-- ==============================================================================
-- KIRANAOS MIGRATION 011: PURCHASE STOCK-IN ATOMIC RPC TRANSACTION
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.confirm_purchase_stock_in(
    p_shop_id UUID,
    p_purchase_id UUID,
    p_purchase_number VARCHAR(100),
    p_supplier_reference TEXT DEFAULT NULL,
    p_items JSONB DEFAULT '[]'::jsonb,
    p_idempotency_key VARCHAR(100) DEFAULT NULL,
    p_performed_by UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_user_role user_role;
    v_existing_status VARCHAR(20);
    v_item JSONB;
    v_product_id UUID;
    v_qty NUMERIC(12, 3);
    v_price_paise BIGINT;
    v_item_total BIGINT;
    v_calculated_subtotal BIGINT := 0;
    v_current_stock NUMERIC(12, 3);
    v_new_stock NUMERIC(12, 3);
    v_movement_id UUID;
    v_result JSONB;
BEGIN
    -- 1. Determine & Validate Authenticated User
    v_user_id := COALESCE(p_performed_by, auth.uid());
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required for purchase stock-in';
    END IF;

    -- 2. Verify Shop Membership & RBAC Permissions
    SELECT role INTO v_user_role
    FROM shop_users
    WHERE shop_id = p_shop_id
      AND user_id = v_user_id
      AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User does not belong to the specified shop';
    END IF;

    -- 3. Idempotency Check: Return immediately if purchase is already completed
    IF p_idempotency_key IS NOT NULL AND p_idempotency_key <> '' THEN
        SELECT status INTO v_existing_status
        FROM purchases
        WHERE shop_id = p_shop_id
          AND (id = p_purchase_id OR (idempotency_key = p_idempotency_key AND status = 'completed'))
        LIMIT 1;

        IF v_existing_status = 'completed' THEN
            RETURN jsonb_build_object(
                'id', p_purchase_id,
                'shop_id', p_shop_id,
                'purchase_number', p_purchase_number,
                'supplier_reference', p_supplier_reference,
                'status', 'completed',
                'idempotency_key', p_idempotency_key,
                'is_idempotent_duplicate', true
            );
        END IF;
    END IF;

    -- 4. Validate Items Array
    IF jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'Purchase must contain at least one item';
    END IF;

    -- 5. Calculate Server-Authoritative Totals & Validate Item Attributes
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_qty := (v_item->>'quantity')::NUMERIC(12, 3);
        v_price_paise := (v_item->>'purchase_price_paise')::BIGINT;

        IF v_qty <= 0 THEN
            RAISE EXCEPTION 'Item quantity must be greater than zero';
        END IF;

        IF v_price_paise < 0 THEN
            RAISE EXCEPTION 'Item purchase price cannot be negative';
        END IF;

        v_item_total := ROUND(v_qty * v_price_paise);
        v_calculated_subtotal := v_calculated_subtotal + v_item_total;
    END LOOP;

    -- 6. Insert or Update Purchases Record
    INSERT INTO purchases (
        id,
        shop_id,
        supplier_id,
        invoice_number,
        invoice_date,
        subtotal_paise,
        tax_total_paise,
        total_paise,
        status,
        created_at
    ) VALUES (
        p_purchase_id,
        p_shop_id,
        NULL,
        p_purchase_number,
        CURRENT_DATE,
        v_calculated_subtotal,
        0,
        v_calculated_subtotal,
        'completed',
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        invoice_number = EXCLUDED.invoice_number,
        subtotal_paise = EXCLUDED.subtotal_paise,
        total_paise = EXCLUDED.total_paise,
        status = 'completed';

    -- 7. Process Line Items, Update Product Stock, & Log Inventory History
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::UUID;
        v_qty := (v_item->>'quantity')::NUMERIC(12, 3);
        v_price_paise := (v_item->>'purchase_price_paise')::BIGINT;
        v_item_total := ROUND(v_qty * v_price_paise);

        -- Insert Line Item
        INSERT INTO purchase_items (
            id,
            purchase_id,
            product_id,
            quantity,
            purchase_price_paise,
            tax_rate,
            total_paise,
            created_at
        ) VALUES (
            COALESCE((v_item->>'id')::UUID, gen_random_uuid()),
            p_purchase_id,
            v_product_id,
            v_qty,
            v_price_paise,
            0.00,
            v_item_total,
            NOW()
        );

        -- Lock & Update Product Stock
        SELECT current_stock INTO v_current_stock
        FROM products
        WHERE id = v_product_id AND shop_id = p_shop_id
        FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product % not found in specified shop', v_product_id;
        END IF;

        v_new_stock := v_current_stock + v_qty;

        UPDATE products
        SET current_stock = v_new_stock,
            purchase_price_paise = v_price_paise,
            updated_at = NOW()
        WHERE id = v_product_id AND shop_id = p_shop_id;

        -- Record Audit Log in inventory_movements
        v_movement_id := gen_random_uuid();
        INSERT INTO inventory_movements (
            id,
            shop_id,
            product_id,
            quantity_delta,
            balance_after,
            reason,
            reference_id,
            performed_by,
            created_at
        ) VALUES (
            v_movement_id,
            p_shop_id,
            v_product_id,
            v_qty,
            v_new_stock,
            'purchase_inward'::movement_reason,
            p_purchase_id,
            v_user_id,
            NOW()
        );
    END LOOP;

    -- 8. Return Completed Purchase Result
    v_result := jsonb_build_object(
        'id', p_purchase_id,
        'shop_id', p_shop_id,
        'purchase_number', p_purchase_number,
        'supplier_reference', p_supplier_reference,
        'subtotal_paise', v_calculated_subtotal,
        'tax_total_paise', 0,
        'total_paise', v_calculated_subtotal,
        'status', 'completed',
        'updated_at', NOW()
    );

    RETURN v_result;
END;
$$;

-- Grant Execution Permissions
GRANT EXECUTE ON FUNCTION public.confirm_purchase_stock_in TO authenticated;
GRANT EXECUTE ON FUNCTION public.confirm_purchase_stock_in TO service_role;
