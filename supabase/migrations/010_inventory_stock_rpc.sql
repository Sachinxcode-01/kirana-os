-- ==============================================================================
-- KIRANAOS MIGRATION 010: INVENTORY STOCK TRANSACTION RPC & SECURITY
-- ==============================================================================

-- 1. Create Stock Adjustment RPC Function (Server-Authoritative Transaction)
CREATE OR REPLACE FUNCTION public.adjust_product_stock(
    p_shop_id UUID,
    p_product_id UUID,
    p_quantity_delta NUMERIC(12, 3),
    p_reason movement_reason,
    p_reference_id UUID DEFAULT NULL,
    p_performed_by UUID DEFAULT NULL,
    p_note TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_stock NUMERIC(12, 3);
    v_new_stock NUMERIC(12, 3);
    v_movement_id UUID;
    v_user_id UUID;
    v_result JSONB;
BEGIN
    -- Determine performed_by user
    v_user_id := COALESCE(p_performed_by, auth.uid());
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to perform stock adjustment';
    END IF;

    -- Verify shop isolation and membership
    IF NOT EXISTS (
        SELECT 1 FROM shop_users
        WHERE shop_id = p_shop_id
          AND user_id = v_user_id
          AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'User does not belong to the specified shop';
    END IF;

    -- Lock and retrieve current product stock (Row-Level Locking for Concurrency)
    SELECT current_stock INTO v_current_stock
    FROM products
    WHERE id = p_product_id AND shop_id = p_shop_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Product not found in the specified shop';
    END IF;

    -- Calculate new stock balance
    v_new_stock := v_current_stock + p_quantity_delta;

    -- Update product current_stock atomically
    UPDATE products
    SET current_stock = v_new_stock,
        updated_at = NOW()
    WHERE id = p_product_id AND shop_id = p_shop_id;

    -- Insert audit log into inventory_movements
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
        p_product_id,
        p_quantity_delta,
        v_new_stock,
        p_reason,
        p_reference_id,
        v_user_id,
        NOW()
    );

    -- Build return payload
    v_result := jsonb_build_object(
        'movement_id', v_movement_id,
        'product_id', p_product_id,
        'previous_stock', v_current_stock,
        'new_stock', v_new_stock,
        'quantity_delta', p_quantity_delta,
        'reason', p_reason,
        'updated_at', NOW()
    );

    RETURN v_result;
END;
$$;

-- Grant execution to authenticated users
GRANT EXECUTE ON FUNCTION public.adjust_product_stock TO authenticated;
GRANT EXECUTE ON FUNCTION public.adjust_product_stock TO service_role;

-- 2. Indexes for fast inventory history queries & lower stock filtering
CREATE INDEX IF NOT EXISTS idx_inventory_movements_shop_product 
ON inventory_movements(shop_id, product_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_products_shop_low_stock 
ON products(shop_id, current_stock, min_stock_alert);
