-- ==============================================================================
-- KiranaOS — Phase 18: Migration 032: Inventory Forecasting & Replenishment Engine
-- Daily Sales Velocity, Reorder Calculation, Dead Stock Analysis & 1-Click PO Drafting
-- ==============================================================================

-- 1. RPC: Calculate Inventory Velocity & Reorder Recommendations
CREATE OR REPLACE FUNCTION public.calculate_inventory_velocity_and_reorder(
    p_shop_id UUID,
    p_days_lookback INTEGER DEFAULT 30
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role user_role;
    v_lookback_days NUMERIC := GREATEST(p_days_lookback, 1);
    v_start_date TIMESTAMPTZ := NOW() - (v_lookback_days || ' days')::interval;
    v_items JSONB := '[]'::jsonb;
    v_critical_count INTEGER := 0;
    v_warning_count INTEGER := 0;
BEGIN
    SELECT role INTO v_user_role
    FROM shop_users
    WHERE shop_id = p_shop_id AND user_id = auth.uid() AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Access Denied: Caller is not an active member of shop %', p_shop_id;
    END IF;

    WITH sales_summary AS (
        SELECT 
            bi.product_id,
            SUM(bi.quantity) as units_sold
        FROM bill_items bi
        JOIN bills b ON b.id = bi.bill_id
        WHERE b.shop_id = p_shop_id 
          AND b.status = 'completed'
          AND b.created_at >= v_start_date
        GROUP BY bi.product_id
    ),
    product_metrics AS (
        SELECT 
            p.id as product_id,
            p.name as product_name,
            p.selling_price_paise,
            p.cost_price_paise,
            p.current_stock,
            p.min_stock_threshold,
            p.unit,
            COALESCE(ss.units_sold, 0) as units_sold_period,
            ROUND((COALESCE(ss.units_sold, 0) / v_lookback_days)::numeric, 3) as daily_velocity,
            CASE 
                WHEN COALESCE(ss.units_sold, 0) > 0 THEN 
                    ROUND((p.current_stock / (ss.units_sold / v_lookback_days))::numeric, 1)
                ELSE NULL
            END as days_of_inventory,
            CASE
                WHEN p.current_stock <= 0 THEN 'OUT_OF_STOCK'
                WHEN p.current_stock <= p.min_stock_threshold THEN 'CRITICAL'
                WHEN COALESCE(ss.units_sold, 0) > 0 AND (p.current_stock / (ss.units_sold / v_lookback_days)) <= 7 THEN 'WARNING'
                ELSE 'HEALTHY'
            END as stock_health,
            GREATEST(
                CEIL(( (COALESCE(ss.units_sold, 0) / v_lookback_days) * 7 ) + p.min_stock_threshold - p.current_stock),
                0
            )::numeric(12,3) as suggested_reorder_qty
        FROM products p
        LEFT JOIN sales_summary ss ON ss.product_id = p.id
        WHERE p.shop_id = p_shop_id AND p.is_active = TRUE
    )
    SELECT 
        jsonb_agg(
            jsonb_build_object(
                'product_id', product_id,
                'product_name', product_name,
                'selling_price_paise', selling_price_paise,
                'cost_price_paise', cost_price_paise,
                'current_stock', current_stock,
                'min_stock_threshold', min_stock_threshold,
                'unit', unit,
                'units_sold_period', units_sold_period,
                'daily_velocity', daily_velocity,
                'days_of_inventory', days_of_inventory,
                'stock_health', stock_health,
                'suggested_reorder_qty', suggested_reorder_qty
            ) ORDER BY 
                CASE stock_health 
                    WHEN 'OUT_OF_STOCK' THEN 1 
                    WHEN 'CRITICAL' THEN 2 
                    WHEN 'WARNING' THEN 3 
                    ELSE 4 
                END ASC,
                units_sold_period DESC
        ),
        COUNT(*) FILTER (WHERE stock_health IN ('OUT_OF_STOCK', 'CRITICAL')),
        COUNT(*) FILTER (WHERE stock_health = 'WARNING')
    INTO v_items, v_critical_count, v_warning_count
    FROM product_metrics;

    RETURN jsonb_build_object(
        'shop_id', p_shop_id,
        'lookback_days', p_days_lookback,
        'critical_items_count', COALESCE(v_critical_count, 0),
        'warning_items_count', COALESCE(v_warning_count, 0),
        'total_products_analyzed', jsonb_array_length(COALESCE(v_items, '[]'::jsonb)),
        'recommendations', COALESCE(v_items, '[]'::jsonb)
    );
END;
$$;

-- 2. RPC: Generate Auto-Replenishment Purchase Order Draft
CREATE OR REPLACE FUNCTION public.generate_auto_replenishment_po(
    p_shop_id UUID,
    p_supplier_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role user_role;
    v_supplier RECORD;
    v_po_id UUID := gen_random_uuid();
    v_po_number VARCHAR(50);
    v_subtotal_paise BIGINT := 0;
    v_total_items INTEGER := 0;
    v_item RECORD;
    v_item_subtotal BIGINT;
BEGIN
    SELECT role INTO v_user_role
    FROM shop_users
    WHERE shop_id = p_shop_id AND user_id = auth.uid() AND status = 'active';

    IF NOT FOUND OR v_user_role NOT IN ('owner', 'manager') THEN
        RAISE EXCEPTION 'Access Denied: Only owners or managers can generate replenishment POs';
    END IF;

    SELECT * INTO v_supplier
    FROM suppliers
    WHERE id = p_supplier_id AND shop_id = p_shop_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Supplier % not found in shop %', p_supplier_id, p_shop_id;
    END IF;

    v_po_number := 'PO-AUTO-' || TO_CHAR(NOW(), 'YYYYMMDD-HH24MI');

    -- Insert Draft PO Header
    INSERT INTO purchases (
        id, shop_id, supplier_id, invoice_number,
        purchase_date, subtotal_paise, tax_paise, total_paise,
        status, created_by, created_at, updated_at
    ) VALUES (
        v_po_id, p_shop_id, p_supplier_id, v_po_number,
        CURRENT_DATE, 0, 0, 0,
        'draft', auth.uid(), NOW(), NOW()
    );

    -- Find Products below min_stock_threshold and insert line items
    FOR v_item IN (
        SELECT 
            p.id as product_id,
            p.name as product_name,
            p.cost_price_paise,
            GREATEST(CEIL(p.min_stock_threshold * 2 - p.current_stock), 10)::numeric(12,3) as reorder_qty
        FROM products p
        WHERE p.shop_id = p_shop_id 
          AND p.is_active = TRUE
          AND p.current_stock <= p.min_stock_threshold
    ) LOOP
        v_item_subtotal := (v_item.reorder_qty * v_item.cost_price_paise)::bigint;
        v_subtotal_paise := v_subtotal_paise + v_item_subtotal;
        v_total_items := v_total_items + 1;

        INSERT INTO purchase_items (
            id, purchase_id, product_id,
            quantity, unit_cost_paise, tax_rate,
            tax_amount_paise, total_cost_paise, created_at
        ) VALUES (
            gen_random_uuid(), v_po_id, v_item.product_id,
            v_item.reorder_qty, v_item.cost_price_paise, 0.00,
            0, v_item_subtotal, NOW()
        );
    END LOOP;

    -- Update PO Header totals
    UPDATE purchases
    SET subtotal_paise = v_subtotal_paise,
        total_paise = v_subtotal_paise
    WHERE id = v_po_id;

    RETURN jsonb_build_object(
        'success', true,
        'purchase_order_id', v_po_id,
        'po_number', v_po_number,
        'supplier_id', p_supplier_id,
        'supplier_name', v_supplier.name,
        'total_line_items', v_total_items,
        'total_estimated_cost_paise', v_subtotal_paise,
        'status', 'draft'
    );
END;
$$;

-- 3. RPC: Get Dead Stock Analysis Report
CREATE OR REPLACE FUNCTION public.get_dead_stock_report(
    p_shop_id UUID,
    p_unmoved_days INTEGER DEFAULT 60
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role user_role;
    v_cutoff TIMESTAMPTZ := NOW() - (p_unmoved_days || ' days')::interval;
    v_dead_stock JSONB := '[]'::jsonb;
    v_total_tied_capital BIGINT := 0;
BEGIN
    SELECT role INTO v_user_role
    FROM shop_users
    WHERE shop_id = p_shop_id AND user_id = auth.uid() AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Access Denied: Caller is not an active member of shop %', p_shop_id;
    END IF;

    WITH recent_sales AS (
        SELECT DISTINCT bi.product_id
        FROM bill_items bi
        JOIN bills b ON b.id = bi.bill_id
        WHERE b.shop_id = p_shop_id 
          AND b.status = 'completed'
          AND b.created_at >= v_cutoff
    ),
    dead_items AS (
        SELECT 
            p.id as product_id,
            p.name as product_name,
            p.current_stock,
            p.selling_price_paise,
            p.cost_price_paise,
            (p.current_stock * p.cost_price_paise)::bigint as capital_tied_paise,
            p.unit,
            c.name as category_name,
            p.created_at as added_on
        FROM products p
        LEFT JOIN categories c ON c.id = p.category_id
        LEFT JOIN recent_sales rs ON rs.product_id = p.id
        WHERE p.shop_id = p_shop_id 
          AND p.is_active = TRUE
          AND p.current_stock > 0
          AND rs.product_id IS NULL -- No sales in period
    )
    SELECT 
        jsonb_agg(
            jsonb_build_object(
                'product_id', product_id,
                'product_name', product_name,
                'current_stock', current_stock,
                'selling_price_paise', selling_price_paise,
                'cost_price_paise', cost_price_paise,
                'capital_tied_paise', capital_tied_paise,
                'unit', unit,
                'category_name', category_name,
                'added_on', added_on
            ) ORDER BY capital_tied_paise DESC
        ),
        COALESCE(SUM(capital_tied_paise), 0)
    INTO v_dead_stock, v_total_tied_capital
    FROM dead_items;

    RETURN jsonb_build_object(
        'shop_id', p_shop_id,
        'unmoved_days_threshold', p_unmoved_days,
        'dead_stock_count', jsonb_array_length(COALESCE(v_dead_stock, '[]'::jsonb)),
        'total_capital_tied_paise', v_total_tied_capital,
        'items', COALESCE(v_dead_stock, '[]'::jsonb)
    );
END;
$$;
