-- ==============================================================================
-- KiranaOS — Phase 13.6: Migration 026: Server-Authoritative Sale Checkout RPC
-- Complete Atomic Sale Checkout RPC with Price Change Detection & Stock Validation
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.execute_authoritative_checkout(
    p_bill_id UUID,
    p_shop_id UUID,
    p_cashier_id UUID,
    p_payment_mode payment_mode,
    p_payment_amount_paise BIGINT,
    p_discount_type VARCHAR DEFAULT 'none',
    p_discount_value NUMERIC DEFAULT 0.00,
    p_customer_id UUID DEFAULT NULL,
    p_idempotency_key TEXT DEFAULT NULL,
    p_reference_number TEXT DEFAULT NULL,
    p_items JSONB DEFAULT '[]'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role user_role;
    v_bill RECORD;
    v_item JSONB;
    v_product_id UUID;
    v_qty NUMERIC(12, 3);
    v_submitted_price BIGINT;
    v_product_name VARCHAR(255);
    v_current_price BIGINT;
    v_current_stock NUMERIC(12, 3);
    v_tax_rate NUMERIC(5, 2);
    v_is_active BOOLEAN;
    v_item_subtotal BIGINT := 0;
    v_item_tax BIGINT := 0;
    v_calculated_subtotal BIGINT := 0;
    v_calculated_tax BIGINT := 0;
    v_calculated_discount BIGINT := 0;
    v_calculated_total BIGINT := 0;
    v_bill_number VARCHAR(50);
    v_payment_id UUID;
    v_now TIMESTAMPTZ := NOW();
    v_new_stock NUMERIC(12, 3);
BEGIN
    -- 1. Security Check: Caller must belong to the active shop
    SELECT role INTO v_user_role
    FROM shop_users
    WHERE shop_id = p_shop_id AND user_id = auth.uid() AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Access Denied: Caller is not an active member of shop %', p_shop_id;
    END IF;

    -- Security Check: Inventory staff are restricted from completing sales
    IF v_user_role = 'inventory_staff' THEN
        RAISE EXCEPTION 'Access Denied: Inventory staff are not authorized to process sale checkout';
    END IF;

    -- 2. Idempotency Check
    IF p_idempotency_key IS NOT NULL AND TRIM(p_idempotency_key) <> '' THEN
        SELECT * INTO v_bill FROM bills WHERE id = p_bill_id AND shop_id = p_shop_id FOR UPDATE;
        IF FOUND AND v_bill.status = 'completed' THEN
            RETURN jsonb_build_object(
                'status', 'SUCCESS',
                'bill_id', v_bill.id,
                'bill_number', v_bill.bill_number,
                'total_paise', v_bill.total_paise,
                'already_completed', true
            );
        END IF;
    END IF;

    -- 3. Validate Cart Not Empty
    IF jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'Cannot checkout an empty cart.';
    END IF;

    -- 4. Server-Authoritative Product & Price Validation Loop
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
        v_product_id := (v_item->>'product_id')::UUID;
        v_qty := (v_item->>'quantity')::NUMERIC(12, 3);
        v_submitted_price := (v_item->>'unit_price_paise')::BIGINT;

        IF v_qty <= 0 THEN
            RAISE EXCEPTION 'Invalid product quantity: %', v_qty;
        END IF;

        -- Lock target product for stock & price verification
        SELECT name, selling_price_paise, current_stock, tax_rate_percentage, is_active
        INTO v_product_name, v_current_price, v_current_stock, v_tax_rate, v_is_active
        FROM products
        WHERE id = v_product_id AND shop_id = p_shop_id FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product % not found in catalog.', v_product_id;
        END IF;

        IF NOT v_is_active THEN
            RAISE EXCEPTION 'Product "%" is no longer active.', v_product_name;
        END IF;

        -- PRICE CHANGE DETECTION: Throw specific exception if price changed
        IF v_submitted_price <> v_current_price THEN
            RAISE EXCEPTION 'PRICE_CHANGED: Product price changed for "%". Current price: ₹%. Please review your cart.',
                v_product_name, (v_current_price / 100.0)::NUMERIC(12, 2);
        END IF;

        -- STOCK VERIFICATION: Prevent negative stock / overselling
        IF v_current_stock < v_qty THEN
            RAISE EXCEPTION 'INSUFFICIENT_STOCK: Insufficient stock for product "%": requested %, available %',
                v_product_name, v_qty, v_current_stock;
        END IF;

        -- Calculate item totals
        v_item_subtotal := (v_current_price * v_qty)::BIGINT;
        v_calculated_subtotal := v_calculated_subtotal + v_item_subtotal;
    END LOOP;

    -- 5. Calculate Discount & Taxes
    IF p_discount_type = 'percentage' THEN
        v_calculated_discount := ((v_calculated_subtotal * (LEAST(p_discount_value, 100.0) / 100.0)))::BIGINT;
    ELSIF p_discount_type = 'fixed' THEN
        v_calculated_discount := LEAST(p_discount_value::BIGINT, v_calculated_subtotal);
    END IF;

    v_calculated_total := GREATEST(0, v_calculated_subtotal - v_calculated_discount + v_calculated_tax);

    -- 6. Payment Amount Validation
    IF p_payment_amount_paise <> v_calculated_total THEN
        RAISE EXCEPTION 'Payment amount mismatch: Calculated total is %, but submitted payment is %',
            v_calculated_total, p_payment_amount_paise;
    END IF;

    -- 7. Generate Bill Number
    v_bill_number := 'INV-' || TO_CHAR(v_now, 'YYYYMMDD') || '-' || SUBSTRING(p_bill_id::text FROM 1 FOR 6);

    -- 8. Create Bill Record (Server Authoritative)
    INSERT INTO bills (
        id, shop_id, bill_number, cashier_id, customer_id,
        subtotal_paise, discount_type, discount_value, discount_paise,
        tax_total_paise, total_paise, status, payment_status, created_at, updated_at
    ) VALUES (
        p_bill_id, p_shop_id, v_bill_number, p_cashier_id, p_customer_id,
        v_calculated_subtotal, p_discount_type, p_discount_value, v_calculated_discount,
        v_calculated_tax, v_calculated_total, 'completed', 'paid', v_now, v_now
    ) ON CONFLICT (id) DO UPDATE SET
        status = 'completed',
        payment_status = 'paid',
        subtotal_paise = EXCLUDED.subtotal_paise,
        discount_paise = EXCLUDED.discount_paise,
        total_paise = EXCLUDED.total_paise,
        updated_at = v_now;

    -- 9. Insert Bill Items & Deduct Stock
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items) LOOP
        v_product_id := (v_item->>'product_id')::UUID;
        v_qty := (v_item->>'quantity')::NUMERIC(12, 3);
        v_submitted_price := (v_item->>'unit_price_paise')::BIGINT;

        SELECT name, current_stock, tax_rate_percentage INTO v_product_name, v_current_stock, v_tax_rate
        FROM products WHERE id = v_product_id AND shop_id = p_shop_id;

        v_item_subtotal := (v_submitted_price * v_qty)::BIGINT;

        INSERT INTO bill_items (
            id, bill_id, product_id, product_name, quantity, unit_price_paise, tax_rate, tax_amount_paise, total_paise, created_at
        ) VALUES (
            gen_random_uuid(), p_bill_id, v_product_id, v_product_name, v_qty, v_submitted_price, v_tax_rate, 0, v_item_subtotal, v_now
        );

        -- Deduct Stock
        v_new_stock := v_current_stock - v_qty;
        UPDATE products SET current_stock = v_new_stock, updated_at = v_now WHERE id = v_product_id AND shop_id = p_shop_id;

        -- Create Immutable Inventory Movement Log
        INSERT INTO inventory_movements (
            id, shop_id, product_id, previous_quantity, quantity_delta, balance_after,
            reason, reference_id, performed_by, created_at
        ) VALUES (
            gen_random_uuid(), p_shop_id, v_product_id, v_current_stock, -v_qty, v_new_stock,
            'sale'::movement_reason, p_bill_id, p_cashier_id, v_now
        );
    END LOOP;

    -- 10. Create Immutable Payment Record
    v_payment_id := gen_random_uuid();
    INSERT INTO payments (
        id, shop_id, bill_id, mode, amount_paise, status, reference_number, created_at, updated_at
    ) VALUES (
        v_payment_id, p_shop_id, p_bill_id, p_payment_mode, v_calculated_total, 'success', p_reference_number, v_now, v_now
    );

    RETURN jsonb_build_object(
        'status', 'SUCCESS',
        'bill_id', p_bill_id,
        'bill_number', v_bill_number,
        'payment_id', v_payment_id,
        'total_paise', v_calculated_total,
        'completed_at', v_now
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.execute_authoritative_checkout TO authenticated;
