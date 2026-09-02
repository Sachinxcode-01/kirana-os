-- ==============================================================================
-- KiranaOS — Phase 15: Migration 029: Customer Khata / Udhaar Digital Ledger RPCs
-- Full Credit Management, Settlement, Audit Reconciliation, and Statement Generation
-- All financial calculations strictly in Paise (BIGINT)
-- ==============================================================================

-- 1. RPC: Record Customer Credit Transaction
CREATE OR REPLACE FUNCTION public.record_credit_transaction(
    p_shop_id UUID,
    p_customer_id UUID,
    p_bill_id UUID,
    p_transaction_type credit_txn_type,
    p_amount_paise BIGINT,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role user_role;
    v_customer RECORD;
    v_new_balance BIGINT;
    v_txn_id UUID;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    -- Security Check: Caller must belong to the active shop
    SELECT role INTO v_user_role
    FROM shop_users
    WHERE shop_id = p_shop_id AND user_id = auth.uid() AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Access Denied: Caller is not an active member of shop %', p_shop_id;
    END IF;

    IF p_amount_paise <= 0 THEN
        RAISE EXCEPTION 'Invalid Amount: Amount must be greater than 0 Paise';
    END IF;

    -- Fetch Customer
    SELECT * INTO v_customer
    FROM customers
    WHERE id = p_customer_id AND shop_id = p_shop_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer Not Found: % does not exist in shop %', p_customer_id, p_shop_id;
    END IF;

    -- Credit Limit Validation for credit_given
    IF p_transaction_type = 'credit_given' THEN
        IF v_customer.credit_limit_paise > 0 AND (v_customer.current_balance_paise + p_amount_paise) > v_customer.credit_limit_paise THEN
            -- Check if user is manager or owner to allow override
            IF v_user_role NOT IN ('owner', 'manager') THEN
                RAISE EXCEPTION 'Credit Limit Exceeded: Customer limit is ₹%, current balance is ₹%, attempted credit ₹%',
                    (v_customer.credit_limit_paise / 100.0),
                    (v_customer.current_balance_paise / 100.0),
                    (p_amount_paise / 100.0);
            END IF;
        END IF;
        v_new_balance := v_customer.current_balance_paise + p_amount_paise;
    ELSIF p_transaction_type IN ('payment_received', 'bad_debt_writeoff') THEN
        v_new_balance := v_customer.current_balance_paise - p_amount_paise;
    ELSE
        RAISE EXCEPTION 'Unsupported Transaction Type: %', p_transaction_type;
    END IF;

    -- Insert Transaction Record
    v_txn_id := gen_random_uuid();
    INSERT INTO credit_transactions (
        id, shop_id, customer_id, bill_id,
        transaction_type, amount_paise, notes,
        created_by, created_at
    ) VALUES (
        v_txn_id, p_shop_id, p_customer_id, p_bill_id,
        p_transaction_type, p_amount_paise, p_notes,
        auth.uid(), v_now
    );

    -- Update Customer Record
    UPDATE customers
    SET current_balance_paise = v_new_balance,
        updated_at = v_now
    WHERE id = p_customer_id;

    RETURN jsonb_build_object(
        'success', true,
        'transaction_id', v_txn_id,
        'customer_id', p_customer_id,
        'transaction_type', p_transaction_type,
        'amount_paise', p_amount_paise,
        'previous_balance_paise', v_customer.current_balance_paise,
        'new_balance_paise', v_new_balance,
        'created_at', v_now
    );
END;
$$;

-- 2. RPC: Settle Customer Khata (Khata Payment Settlement)
CREATE OR REPLACE FUNCTION public.settle_customer_khata(
    p_shop_id UUID,
    p_customer_id UUID,
    p_amount_paise BIGINT,
    p_payment_mode payment_mode DEFAULT 'cash',
    p_reference_number TEXT DEFAULT NULL,
    p_notes TEXT DEFAULT 'Khata Balance Settlement'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role user_role;
    v_customer RECORD;
    v_new_balance BIGINT;
    v_txn_id UUID;
    v_payment_id UUID;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT role INTO v_user_role
    FROM shop_users
    WHERE shop_id = p_shop_id AND user_id = auth.uid() AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Access Denied: Caller is not an active member of shop %', p_shop_id;
    END IF;

    IF p_amount_paise <= 0 THEN
        RAISE EXCEPTION 'Invalid Amount: Settlement amount must be greater than 0 Paise';
    END IF;

    SELECT * INTO v_customer
    FROM customers
    WHERE id = p_customer_id AND shop_id = p_shop_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer Not Found: %', p_customer_id;
    END IF;

    v_new_balance := v_customer.current_balance_paise - p_amount_paise;
    v_txn_id := gen_random_uuid();
    v_payment_id := gen_random_uuid();

    -- Record in Credit Ledger
    INSERT INTO credit_transactions (
        id, shop_id, customer_id, bill_id,
        transaction_type, amount_paise, notes,
        created_by, created_at
    ) VALUES (
        v_txn_id, p_shop_id, p_customer_id, NULL,
        'payment_received', p_amount_paise, p_notes,
        auth.uid(), v_now
    );

    -- Record Payment Entry
    INSERT INTO payments (
        id, shop_id, bill_id, payment_mode,
        amount_paise, status, reference_number,
        collected_by, created_at
    ) VALUES (
        v_payment_id, p_shop_id, NULL, p_payment_mode,
        p_amount_paise, 'success', p_reference_number,
        auth.uid(), v_now
    );

    -- Update Customer Balance
    UPDATE customers
    SET current_balance_paise = v_new_balance,
        updated_at = v_now
    WHERE id = p_customer_id;

    RETURN jsonb_build_object(
        'success', true,
        'transaction_id', v_txn_id,
        'payment_id', v_payment_id,
        'customer_id', p_customer_id,
        'customer_name', v_customer.name,
        'amount_settled_paise', p_amount_paise,
        'previous_balance_paise', v_customer.current_balance_paise,
        'new_balance_paise', v_new_balance,
        'payment_mode', p_payment_mode,
        'created_at', v_now
    );
END;
$$;

-- 3. RPC: Reconcile Customer Balance (Ledger Re-calculation)
CREATE OR REPLACE FUNCTION public.reconcile_customer_balance(
    p_shop_id UUID,
    p_customer_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_customer RECORD;
    v_computed_balance BIGINT := 0;
    v_discrepancy BIGINT := 0;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT * INTO v_customer
    FROM customers
    WHERE id = p_customer_id AND shop_id = p_shop_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer % not found in shop %', p_customer_id, p_shop_id;
    END IF;

    -- Compute absolute ledger balance
    SELECT COALESCE(
        SUM(
            CASE 
                WHEN transaction_type = 'credit_given' THEN amount_paise
                WHEN transaction_type IN ('payment_received', 'bad_debt_writeoff') THEN -amount_paise
                ELSE 0
            END
        ), 0
    ) INTO v_computed_balance
    FROM credit_transactions
    WHERE customer_id = p_customer_id AND shop_id = p_shop_id;

    v_discrepancy := v_customer.current_balance_paise - v_computed_balance;

    -- Correct balance if there is discrepancy
    IF v_discrepancy != 0 THEN
        UPDATE customers
        SET current_balance_paise = v_computed_balance,
            updated_at = v_now
        WHERE id = p_customer_id;
    END IF;

    RETURN jsonb_build_object(
        'customer_id', p_customer_id,
        'customer_name', v_customer.name,
        'previous_stored_balance_paise', v_customer.current_balance_paise,
        'computed_ledger_balance_paise', v_computed_balance,
        'discrepancy_corrected_paise', v_discrepancy,
        'is_reconciled', true,
        'timestamp', v_now
    );
END;
$$;

-- 4. RPC: Get Customer Khata Statement
CREATE OR REPLACE FUNCTION public.get_customer_khata_statement(
    p_shop_id UUID,
    p_customer_id UUID,
    p_start_date TIMESTAMPTZ DEFAULT (NOW() - INTERVAL '30 days'),
    p_end_date TIMESTAMPTZ DEFAULT NOW()
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_customer RECORD;
    v_opening_balance BIGINT := 0;
    v_period_credits BIGINT := 0;
    v_period_payments BIGINT := 0;
    v_closing_balance BIGINT := 0;
    v_transactions JSONB := '[]'::jsonb;
BEGIN
    SELECT * INTO v_customer
    FROM customers
    WHERE id = p_customer_id AND shop_id = p_shop_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer % not found in shop %', p_customer_id, p_shop_id;
    END IF;

    -- 1. Compute Opening Balance (All txns prior to p_start_date)
    SELECT COALESCE(
        SUM(
            CASE 
                WHEN transaction_type = 'credit_given' THEN amount_paise
                WHEN transaction_type IN ('payment_received', 'bad_debt_writeoff') THEN -amount_paise
                ELSE 0
            END
        ), 0
    ) INTO v_opening_balance
    FROM credit_transactions
    WHERE customer_id = p_customer_id AND shop_id = p_shop_id AND created_at < p_start_date;

    -- 2. Period Summary
    SELECT 
        COALESCE(SUM(CASE WHEN transaction_type = 'credit_given' THEN amount_paise ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN transaction_type = 'payment_received' THEN amount_paise ELSE 0 END), 0)
    INTO v_period_credits, v_period_payments
    FROM credit_transactions
    WHERE customer_id = p_customer_id AND shop_id = p_shop_id 
      AND created_at >= p_start_date AND created_at <= p_end_date;

    v_closing_balance := v_opening_balance + v_period_credits - v_period_payments;

    -- 3. Detailed Statement Transactions
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', ct.id,
            'bill_id', ct.bill_id,
            'transaction_type', ct.transaction_type,
            'amount_paise', ct.amount_paise,
            'notes', ct.notes,
            'created_at', ct.created_at
        ) ORDER BY ct.created_at ASC
    ) INTO v_transactions
    FROM credit_transactions ct
    WHERE ct.customer_id = p_customer_id AND ct.shop_id = p_shop_id
      AND ct.created_at >= p_start_date AND ct.created_at <= p_end_date;

    RETURN jsonb_build_object(
        'customer_id', p_customer_id,
        'customer_name', v_customer.name,
        'customer_phone', v_customer.phone,
        'statement_start', p_start_date,
        'statement_end', p_end_date,
        'opening_balance_paise', v_opening_balance,
        'total_credit_given_paise', v_period_credits,
        'total_payments_received_paise', v_period_payments,
        'closing_balance_paise', v_closing_balance,
        'current_live_balance_paise', v_customer.current_balance_paise,
        'transactions', COALESCE(v_transactions, '[]'::jsonb)
    );
END;
$$;
