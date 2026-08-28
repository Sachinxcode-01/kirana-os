-- ==============================================================================
-- KiranaOS — Phase 12.6: Migration 023: Payment Foundation & Server-Authoritative Checkout
-- PostgreSQL 16 / Supabase Schema Definition & RPC Function
-- ==============================================================================

-- 1. ENHANCE PAYMENTS TABLE SCHEMA
ALTER TABLE public.payments
    ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'success',
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Ensure check constraint on payment amount
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_payments_amount_positive'
    ) THEN
        ALTER TABLE public.payments
            ADD CONSTRAINT chk_payments_amount_positive CHECK (amount_paise > 0);
    END IF;
END $$;

-- Create index on payments table for faster lookup by bill_id and shop_id
CREATE INDEX IF NOT EXISTS idx_payments_shop_bill ON public.payments(shop_id, bill_id);

-- 2. SERVER-AUTHORITATIVE ATOMIC SALE CHECKOUT RPC
CREATE OR REPLACE FUNCTION public.complete_sale_transaction(
    p_bill_id UUID,
    p_shop_id UUID,
    p_cashier_id UUID,
    p_payment_mode payment_mode,
    p_payment_amount_paise BIGINT,
    p_idempotency_key TEXT DEFAULT NULL,
    p_items JSONB DEFAULT NULL,
    p_reference_number TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_bill RECORD;
    v_item RECORD;
    v_item_json JSONB;
    v_product_id UUID;
    v_qty NUMERIC;
    v_current_stock NUMERIC;
    v_new_stock NUMERIC;
    v_payment_id UUID;
    v_now TIMESTAMPTZ := NOW();
    v_calculated_subtotal BIGINT := 0;
    v_calculated_tax BIGINT := 0;
    v_calculated_discount BIGINT := 0;
    v_calculated_total BIGINT := 0;
BEGIN
    -- Security Check: Caller must belong to the active shop
    IF NOT EXISTS (
        SELECT 1 FROM shop_users 
        WHERE shop_id = p_shop_id AND user_id = auth.uid() AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'Access Denied: Caller is not an active member of shop %', p_shop_id;
    END IF;

    -- Security Check: Inventory staff are restricted from completing sales
    IF EXISTS (
        SELECT 1 FROM shop_users su
        JOIN roles r ON su.role_id = r.id
        WHERE su.shop_id = p_shop_id AND su.user_id = auth.uid() AND r.name = 'inventory_staff'
    ) THEN
        RAISE EXCEPTION 'Access Denied: Inventory staff are not authorized to process sale checkout';
    END IF;

    -- Retrieve existing bill record if present
    SELECT * INTO v_bill FROM bills WHERE id = p_bill_id AND shop_id = p_shop_id FOR UPDATE;

    -- Idempotency Protection: If bill is already completed, return existing completed bill safely
    IF FOUND AND v_bill.status = 'completed' THEN
        RETURN jsonb_build_object(
            'status', 'SUCCESS',
            'bill_id', v_bill.id,
            'bill_number', v_bill.bill_number,
            'already_completed', true
        );
    END IF;

    -- Validation: Amount check
    IF p_payment_amount_paise <= 0 THEN
        RAISE EXCEPTION 'Invalid payment amount: % paise', p_payment_amount_paise;
    END IF;

    -- If bill does not exist yet, create it from items or throw error if items missing
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Bill % not found for shop %', p_bill_id, p_shop_id;
    END IF;

    -- Check bill total matches payment amount
    IF v_bill.total_paise <> p_payment_amount_paise THEN
        RAISE EXCEPTION 'Payment amount mismatch: Bill total is %, but payment submitted is %', 
            v_bill.total_paise, p_payment_amount_paise;
    END IF;

    -- Customer Relationship Validation (if customer assigned)
    IF v_bill.customer_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM customers WHERE id = v_bill.customer_id AND shop_id = p_shop_id
        ) THEN
            RAISE EXCEPTION 'Invalid customer ID % associated with shop %', v_bill.customer_id, p_shop_id;
        END IF;
    END IF;

    -- Process Inventory Stock Check & Movements
    FOR v_item IN SELECT * FROM bill_items WHERE bill_id = p_bill_id LOOP
        v_product_id := v_item.product_id;
        v_qty := v_item.quantity;

        -- Lock product for stock verification
        SELECT current_stock INTO v_current_stock 
        FROM products 
        WHERE id = v_product_id AND shop_id = p_shop_id FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product % not found in shop %', v_product_id, p_shop_id;
        END IF;

        IF v_current_stock < v_qty THEN
            RAISE EXCEPTION 'Insufficient stock for product "%": requested %, available %', 
                v_item.product_name, v_qty, v_current_stock;
        END IF;

        -- Decrement Stock & Insert Movement Entry
        v_new_stock := v_current_stock - v_qty;
        UPDATE products 
        SET current_stock = v_new_stock, updated_at = v_now 
        WHERE id = v_product_id AND shop_id = p_shop_id;

        INSERT INTO inventory_movements (
            id, shop_id, product_id, quantity_delta, balance_after,
            reason, reference_id, performed_by, created_at
        ) VALUES (
            gen_random_uuid(),
            p_shop_id,
            v_product_id,
            -v_qty,
            v_new_stock,
            'sale'::movement_reason,
            p_bill_id,
            auth.uid(),
            v_now
        );
    END LOOP;

    -- Create Payment Record (Immutable Completed Payment Record)
    v_payment_id := gen_random_uuid();
    INSERT INTO payments (
        id, shop_id, bill_id, mode, amount_paise, status, reference_number, created_at, updated_at
    ) VALUES (
        v_payment_id,
        p_shop_id,
        p_bill_id,
        p_payment_mode,
        p_payment_amount_paise,
        'success',
        p_reference_number,
        v_now,
        v_now
    );

    -- Update Bill Status to Completed
    UPDATE bills 
    SET status = 'completed', 
        payment_status = 'paid', 
        updated_at = v_now 
    WHERE id = p_bill_id AND shop_id = p_shop_id;

    RETURN jsonb_build_object(
        'status', 'SUCCESS',
        'bill_id', p_bill_id,
        'payment_id', v_payment_id,
        'bill_number', v_bill.bill_number,
        'amount_paise', p_payment_amount_paise,
        'completed_at', v_now
    );
END;
$$;

-- 3. PREVENT UNORGANIZED EDITS TO COMPLETED PAYMENTS VIA RLS / POLICY
CREATE OR REPLACE FUNCTION public.trg_prevent_completed_payment_modification()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.status = 'success' AND (NEW.amount_paise <> OLD.amount_paise OR NEW.mode <> OLD.mode OR NEW.bill_id <> OLD.bill_id) THEN
        RAISE EXCEPTION 'Completed payment records are immutable and cannot be modified';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS prevent_payment_edit ON public.payments;
CREATE TRIGGER prevent_payment_edit
    BEFORE UPDATE ON public.payments
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_prevent_completed_payment_modification();
