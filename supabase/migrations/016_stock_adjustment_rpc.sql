-- ==============================================================================
-- KIRANAOS MIGRATION 016: ENHANCED ATOMIC STOCK ADJUSTMENT RPC & IMMUTABLE HISTORY
-- ==============================================================================

-- 1. Schema Extensions for inventory_movements
ALTER TABLE public.inventory_movements 
    ADD COLUMN IF NOT EXISTS previous_quantity NUMERIC(12, 3),
    ADD COLUMN IF NOT EXISTS adjustment_reason VARCHAR(100),
    ADD COLUMN IF NOT EXISTS notes TEXT,
    ADD COLUMN IF NOT EXISTS idempotency_key VARCHAR(128);

-- Backfill previous_quantity for existing movements if NULL
UPDATE public.inventory_movements 
SET previous_quantity = balance_after - quantity_delta 
WHERE previous_quantity IS NULL;

-- Idempotency Index
CREATE UNIQUE INDEX IF NOT EXISTS idx_inventory_movements_idempotency 
ON public.inventory_movements(shop_id, idempotency_key) 
WHERE idempotency_key IS NOT NULL;

-- 2. Immutable Movement History Trigger Function
CREATE OR REPLACE FUNCTION public.trg_prevent_inventory_movement_modification()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Completed inventory movement records are immutable and cannot be modified or deleted.';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach Immutability Trigger
DROP TRIGGER IF EXISTS trg_inventory_movements_immutable ON public.inventory_movements;
CREATE TRIGGER trg_inventory_movements_immutable
    BEFORE UPDATE OR DELETE ON public.inventory_movements
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_prevent_inventory_movement_modification();

-- 3. Enhanced Server-Authoritative Stock Adjustment RPC
CREATE OR REPLACE FUNCTION public.adjust_product_stock(
    p_shop_id UUID,
    p_product_id UUID,
    p_quantity_delta NUMERIC(12, 3),
    p_reason TEXT,
    p_reference_id UUID DEFAULT NULL,
    p_performed_by UUID DEFAULT NULL,
    p_note TEXT DEFAULT NULL,
    p_idempotency_key VARCHAR(128) DEFAULT NULL,
    p_adjustment_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_shop_id UUID;
    v_current_stock NUMERIC(12, 3);
    v_new_stock NUMERIC(12, 3);
    v_user_role user_role;
    v_has_permission BOOLEAN := FALSE;
    v_movement_id UUID;
    v_movement_reason_enum movement_reason;
    v_adj_reason TEXT;
    v_existing_id UUID;
    v_existing_prev NUMERIC(12, 3);
    v_existing_delta NUMERIC(12, 3);
    v_existing_after NUMERIC(12, 3);
    v_result JSONB;
BEGIN
    -- 1. Authenticate User
    v_user_id := COALESCE(p_performed_by, auth.uid());
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to perform stock adjustment';
    END IF;

    -- 2. Lock & Retrieve Target Product (Server-Authoritative)
    SELECT shop_id, current_stock INTO v_shop_id, v_current_stock
    FROM products
    WHERE id = p_product_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Product not found in system';
    END IF;

    -- Verify shop isolation if p_shop_id was supplied
    IF p_shop_id IS NOT NULL AND p_shop_id <> v_shop_id THEN
        RAISE EXCEPTION 'Product does not belong to the specified shop';
    END IF;

    -- 3. Verify User Shop Membership & RBAC Permissions
    SELECT role INTO v_user_role
    FROM shop_users
    WHERE shop_id = v_shop_id
      AND user_id = v_user_id
      AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Access Denied: User is not an active member of shop %', v_shop_id;
    END IF;

    -- Check Role & Permission
    IF v_user_role IN ('owner', 'manager', 'inventory_staff') THEN
        v_has_permission := TRUE;
    ELSE
        -- Check explicit permission mapping
        SELECT EXISTS (
            SELECT 1 
            FROM role_permissions rp
            JOIN roles r ON rp.role_id = r.id
            JOIN permissions p ON rp.permission_id = p.id
            WHERE r.name = v_user_role AND p.code = 'inventory.adjust'
        ) INTO v_has_permission;
    END IF;

    IF NOT v_has_permission THEN
        RAISE EXCEPTION 'Permission Denied: User role "%" does not have inventory adjustment permission (inventory.adjust)', v_user_role;
    END IF;

    -- 4. Check Idempotency Protection
    IF p_idempotency_key IS NOT NULL AND TRIM(p_idempotency_key) <> '' THEN
        SELECT id, previous_quantity, quantity_delta, balance_after
        INTO v_existing_id, v_existing_prev, v_existing_delta, v_existing_after
        FROM inventory_movements
        WHERE shop_id = v_shop_id AND idempotency_key = TRIM(p_idempotency_key);

        IF FOUND THEN
            RETURN jsonb_build_object(
                'movement_id', v_existing_id,
                'shop_id', v_shop_id,
                'product_id', p_product_id,
                'previous_stock', v_existing_prev,
                'quantity_delta', v_existing_delta,
                'new_stock', v_existing_after,
                'reason', p_reason,
                'idempotent', TRUE,
                'created_at', NOW()
            );
        END IF;
    END IF;

    -- 5. Reason Validation
    v_adj_reason := COALESCE(p_adjustment_reason, p_reason);
    
    IF v_adj_reason IS NULL OR TRIM(v_adj_reason) = '' THEN
        RAISE EXCEPTION 'Adjustment reason is required';
    END IF;

    -- If reason is "Other", require short explanation note
    IF LOWER(TRIM(v_adj_reason)) = 'other' AND (p_note IS NULL OR TRIM(p_note) = '') THEN
        RAISE EXCEPTION 'Reason "Other" requires a short explanation in notes';
    END IF;

    -- Map movement_reason ENUM for legacy schema compatibility
    IF p_reason IN ('sale', 'sale_return', 'purchase_inward', 'purchase_return', 'stock_adjustment', 'spoilage_damage') THEN
        v_movement_reason_enum := p_reason::movement_reason;
    ELSIF LOWER(v_adj_reason) IN ('damaged', 'expired', 'lost') THEN
        v_movement_reason_enum := 'spoilage_damage'::movement_reason;
    ELSE
        v_movement_reason_enum := 'stock_adjustment'::movement_reason;
    END IF;

    -- 6. Validate New Stock Quantity (Prevent Negative Stock)
    v_new_stock := v_current_stock + p_quantity_delta;
    IF v_new_stock < 0 THEN
        RAISE EXCEPTION 'Insufficient stock: New stock quantity cannot be negative (Current: %, Delta: %)', v_current_stock, p_quantity_delta;
    END IF;

    -- 7. Update Inventory (Products table)
    UPDATE products
    SET current_stock = v_new_stock,
        updated_at = NOW()
    WHERE id = p_product_id AND shop_id = v_shop_id;

    -- 8. Create Immutable Stock Movement Log
    v_movement_id := gen_random_uuid();
    INSERT INTO inventory_movements (
        id,
        shop_id,
        product_id,
        previous_quantity,
        quantity_delta,
        balance_after,
        reason,
        adjustment_reason,
        notes,
        reference_id,
        performed_by,
        idempotency_key,
        created_at
    ) VALUES (
        v_movement_id,
        v_shop_id,
        p_product_id,
        v_current_stock,
        p_quantity_delta,
        v_new_stock,
        v_movement_reason_enum,
        v_adj_reason,
        p_note,
        p_reference_id,
        v_user_id,
        TRIM(p_idempotency_key),
        NOW()
    );

    -- 9. Return Response Payload
    v_result := jsonb_build_object(
        'movement_id', v_movement_id,
        'shop_id', v_shop_id,
        'product_id', p_product_id,
        'previous_stock', v_current_stock,
        'new_stock', v_new_stock,
        'quantity_delta', p_quantity_delta,
        'reason', v_movement_reason_enum,
        'adjustment_reason', v_adj_reason,
        'notes', p_note,
        'performed_by', v_user_id,
        'created_at', NOW()
    );

    RETURN v_result;
END;
$$;

-- Grant Execution Permissions
GRANT EXECUTE ON FUNCTION public.adjust_product_stock TO authenticated;
GRANT EXECUTE ON FUNCTION public.adjust_product_stock TO service_role;
