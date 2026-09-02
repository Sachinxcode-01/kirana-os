-- ==============================================================================
-- KiranaOS — Phase 17: Migration 033: Day-End Z-Report & Cashier Audit System
-- Shift Management, Real-Time Drawer Reconciliation, Variance Audit & Cashier Metrics
-- ==============================================================================

-- 1. CASH REGISTERS TABLE
CREATE TABLE IF NOT EXISTS cash_registers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL DEFAULT 'Main Counter',
    status VARCHAR(20) NOT NULL DEFAULT 'closed', -- 'open', 'closed'
    current_shift_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(shop_id, name)
);

-- 2. REGISTER SHIFTS TABLE
CREATE TABLE IF NOT EXISTS register_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    register_id UUID NOT NULL REFERENCES cash_registers(id) ON DELETE CASCADE,
    cashier_id UUID NOT NULL REFERENCES auth.users(id),
    status VARCHAR(20) NOT NULL DEFAULT 'open', -- 'open', 'closed'
    opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at TIMESTAMPTZ,
    opening_cash_paise BIGINT NOT NULL DEFAULT 0,
    closing_cash_actual_paise BIGINT,
    expected_cash_paise BIGINT,
    cash_variance_paise BIGINT,
    total_cash_sales_paise BIGINT DEFAULT 0,
    total_upi_sales_paise BIGINT DEFAULT 0,
    total_card_sales_paise BIGINT DEFAULT 0,
    total_credit_sales_paise BIGINT DEFAULT 0,
    total_credit_collected_paise BIGINT DEFAULT 0,
    total_expenses_payout_paise BIGINT DEFAULT 0,
    total_supplier_payout_paise BIGINT DEFAULT 0,
    bills_count INTEGER DEFAULT 0,
    items_scanned_count INTEGER DEFAULT 0,
    voided_bills_count INTEGER DEFAULT 0,
    discount_overrides_paise BIGINT DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shifts_shop ON register_shifts(shop_id, opened_at DESC);
CREATE INDEX IF NOT EXISTS idx_shifts_register ON register_shifts(register_id);

ALTER TABLE cash_registers ENABLE ROW LEVEL SECURITY;
ALTER TABLE register_shifts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Shop members access cash registers" ON cash_registers
    FOR ALL USING (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY "Shop members access register shifts" ON register_shifts
    FOR ALL USING (shop_id IN (SELECT get_user_shop_ids()));

-- 3. RPC: Open Register Shift
CREATE OR REPLACE FUNCTION public.open_register_shift(
    p_shop_id UUID,
    p_register_id UUID,
    p_opening_cash_paise BIGINT DEFAULT 0,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role user_role;
    v_register RECORD;
    v_shift_id UUID := gen_random_uuid();
    v_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT role INTO v_user_role
    FROM shop_users
    WHERE shop_id = p_shop_id AND user_id = auth.uid() AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Access Denied: Caller is not an active member of shop %', p_shop_id;
    END IF;

    SELECT * INTO v_register
    FROM cash_registers
    WHERE id = p_register_id AND shop_id = p_shop_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Register % not found in shop %', p_register_id, p_shop_id;
    END IF;

    IF v_register.status = 'open' THEN
        RAISE EXCEPTION 'Register % is already open under shift %', v_register.name, v_register.current_shift_id;
    END IF;

    -- Create new shift
    INSERT INTO register_shifts (
        id, shop_id, register_id, cashier_id,
        status, opened_at, opening_cash_paise, notes
    ) VALUES (
        v_shift_id, p_shop_id, p_register_id, auth.uid(),
        'open', v_now, p_opening_cash_paise, p_notes
    );

    -- Update Register state
    UPDATE cash_registers
    SET status = 'open',
        current_shift_id = v_shift_id,
        updated_at = v_now
    WHERE id = p_register_id;

    RETURN jsonb_build_object(
        'success', true,
        'shift_id', v_shift_id,
        'register_id', p_register_id,
        'register_name', v_register.name,
        'opened_at', v_now,
        'opening_cash_paise', p_opening_cash_paise
    );
END;
$$;

-- 4. RPC: Close Register Shift & Generate Z-Report
CREATE OR REPLACE FUNCTION public.close_and_generate_z_report(
    p_shift_id UUID,
    p_actual_cash_paise BIGINT,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role user_role;
    v_shift RECORD;
    v_register RECORD;
    v_shop RECORD;
    v_now TIMESTAMPTZ := NOW();

    -- Sales Metrics
    v_cash_sales BIGINT := 0;
    v_upi_sales BIGINT := 0;
    v_card_sales BIGINT := 0;
    v_credit_sales BIGINT := 0;
    v_gross_sales BIGINT := 0;
    v_total_discount BIGINT := 0;
    v_total_tax BIGINT := 0;
    v_bills_count INTEGER := 0;
    v_items_count INTEGER := 0;
    v_voided_bills INTEGER := 0;

    -- Cash Drawer Inflow / Outflow
    v_credit_collected BIGINT := 0;
    v_petty_expenses BIGINT := 0;
    v_supplier_payouts BIGINT := 0;

    -- Reconciliation Calculations
    v_expected_cash BIGINT := 0;
    v_cash_variance BIGINT := 0;
BEGIN
    -- Fetch Shift
    SELECT * INTO v_shift FROM register_shifts WHERE id = p_shift_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Shift % not found', p_shift_id;
    END IF;

    IF v_shift.status = 'closed' THEN
        RAISE EXCEPTION 'Shift % is already closed', p_shift_id;
    END IF;

    -- Security Check
    SELECT role INTO v_user_role
    FROM shop_users
    WHERE shop_id = v_shift.shop_id AND user_id = auth.uid() AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Access Denied for shop %', v_shift.shop_id;
    END IF;

    SELECT * INTO v_shop FROM shops WHERE id = v_shift.shop_id;
    SELECT * INTO v_register FROM cash_registers WHERE id = v_shift.register_id;

    -- 1. Calculate Sales Breakdowns for this shift
    SELECT 
        COALESCE(SUM(CASE WHEN payment_mode = 'cash' THEN final_amount_paise ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN payment_mode = 'upi_qr' THEN final_amount_paise ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN payment_mode = 'card' THEN final_amount_paise ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN payment_mode = 'credit_khata' THEN final_amount_paise ELSE 0 END), 0),
        COALESCE(SUM(final_amount_paise), 0),
        COALESCE(SUM(discount_paise), 0),
        COALESCE(SUM(tax_paise), 0),
        COUNT(*)
    INTO v_cash_sales, v_upi_sales, v_card_sales, v_credit_sales, 
         v_gross_sales, v_total_discount, v_total_tax, v_bills_count
    FROM bills
    WHERE shop_id = v_shift.shop_id
      AND cashier_id = v_shift.cashier_id
      AND status = 'completed'
      AND created_at >= v_shift.opened_at
      AND created_at <= v_now;

    -- 2. Count Items Scanned
    SELECT COALESCE(SUM(bi.quantity), 0)::integer INTO v_items_count
    FROM bill_items bi
    JOIN bills b ON b.id = bi.bill_id
    WHERE b.shop_id = v_shift.shop_id
      AND b.cashier_id = v_shift.cashier_id
      AND b.status = 'completed'
      AND b.created_at >= v_shift.opened_at
      AND b.created_at <= v_now;

    -- 3. Count Cancelled / Voided Bills
    SELECT COUNT(*) INTO v_voided_bills
    FROM bills
    WHERE shop_id = v_shift.shop_id
      AND cashier_id = v_shift.cashier_id
      AND status = 'cancelled'
      AND created_at >= v_shift.opened_at
      AND created_at <= v_now;

    -- 4. Credit Collected (Cash Khata Settlements during shift)
    SELECT COALESCE(SUM(p.amount_paise), 0) INTO v_credit_collected
    FROM payments p
    WHERE p.shop_id = v_shift.shop_id
      AND p.collected_by = v_shift.cashier_id
      AND p.payment_mode = 'cash'
      AND p.bill_id IS NULL -- Standalone settlement
      AND p.created_at >= v_shift.opened_at
      AND p.created_at <= v_now;

    -- 5. Cash Petty Expenses paid from drawer
    SELECT COALESCE(SUM(amount_paise), 0) INTO v_petty_expenses
    FROM expenses
    WHERE shop_id = v_shift.shop_id
      AND recorded_by = v_shift.cashier_id
      AND payment_mode = 'cash'
      AND created_at >= v_shift.opened_at
      AND created_at <= v_now;

    -- 6. Supplier Cash Payouts
    SELECT COALESCE(SUM(amount_paise), 0) INTO v_supplier_payouts
    FROM supplier_payments
    WHERE shop_id = v_shift.shop_id
      AND payment_mode = 'cash'
      AND created_at >= v_shift.opened_at
      AND created_at <= v_now;

    -- 7. Mathematical Reconciliation
    v_expected_cash := v_shift.opening_cash_paise + v_cash_sales + v_credit_collected - v_petty_expenses - v_supplier_payouts;
    v_cash_variance := p_actual_cash_paise - v_expected_cash;

    -- 8. Update Shift Record
    UPDATE register_shifts
    SET status = 'closed',
        closed_at = v_now,
        closing_cash_actual_paise = p_actual_cash_paise,
        expected_cash_paise = v_expected_cash,
        cash_variance_paise = v_cash_variance,
        total_cash_sales_paise = v_cash_sales,
        total_upi_sales_paise = v_upi_sales,
        total_card_sales_paise = v_card_sales,
        total_credit_sales_paise = v_credit_sales,
        total_credit_collected_paise = v_credit_collected,
        total_expenses_payout_paise = v_petty_expenses,
        total_supplier_payout_paise = v_supplier_payouts,
        bills_count = v_bills_count,
        items_scanned_count = v_items_count,
        voided_bills_count = v_voided_bills,
        discount_overrides_paise = v_total_discount,
        notes = p_notes
    WHERE id = p_shift_id;

    -- 9. Update Cash Register
    UPDATE cash_registers
    SET status = 'closed',
        current_shift_id = NULL,
        updated_at = v_now
    WHERE id = v_shift.register_id;

    -- 10. Construct Final Z-Report Payload
    RETURN jsonb_build_object(
        'report_title', 'DAY-END Z-REPORT (CASH RECONCILIATION)',
        'shop_name', v_shop.name,
        'gstin', v_shop.gstin,
        'register_name', v_register.name,
        'shift_id', p_shift_id,
        'opened_at', v_shift.opened_at,
        'closed_at', v_now,
        'cashier_id', v_shift.cashier_id,
        'cash_reconciliation', jsonb_build_object(
            'opening_cash_paise', v_shift.opening_cash_paise,
            'cash_sales_paise', v_cash_sales,
            'khata_credit_collected_cash_paise', v_credit_collected,
            'petty_expenses_paid_paise', v_petty_expenses,
            'supplier_cash_payouts_paise', v_supplier_payouts,
            'expected_closing_cash_paise', v_expected_cash,
            'actual_drawer_cash_paise', p_actual_cash_paise,
            'variance_paise', v_cash_variance,
            'is_balanced', (v_cash_variance = 0)
        ),
        'sales_summary', jsonb_build_object(
            'gross_sales_paise', v_gross_sales,
            'cash_sales_paise', v_cash_sales,
            'upi_sales_paise', v_upi_sales,
            'card_sales_paise', v_card_sales,
            'credit_khata_sales_paise', v_credit_sales,
            'total_discounts_paise', v_total_discount,
            'total_gst_collected_paise', v_total_tax,
            'total_bills_count', v_bills_count,
            'total_items_scanned', v_items_count,
            'voided_bills_count', v_voided_bills
        )
    );
END;
$$;
