-- ==============================================================================
-- KiranaOS — Phase 16: Migration 030: Customer Loyalty, Rewards & Points System
-- Configurable Shop Loyalty Rules, Ledger Audit, Point Accrual & Redemption RPCs
-- ==============================================================================

-- 1. LOYALTY SETTINGS
CREATE TABLE IF NOT EXISTS loyalty_settings (
    shop_id UUID PRIMARY KEY REFERENCES shops(id) ON DELETE CASCADE,
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    earn_rate_percentage NUMERIC(5,2) NOT NULL DEFAULT 1.00, -- 1 pt per ₹100 spent
    redemption_value_paise BIGINT NOT NULL DEFAULT 100,      -- 1 Point = 100 Paise (₹1.00)
    min_points_to_redeem INTEGER NOT NULL DEFAULT 50,
    points_expiry_days INTEGER NOT NULL DEFAULT 365,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. CUSTOMER LOYALTY LEDGER
CREATE TABLE IF NOT EXISTS customer_loyalty_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    bill_id UUID REFERENCES bills(id) ON DELETE SET NULL,
    transaction_type VARCHAR(20) NOT NULL, -- 'earn', 'redeem', 'manual_adjust', 'expired', 'rollback'
    points_changed INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_loyalty_ledger_customer ON customer_loyalty_ledger(customer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_loyalty_ledger_shop ON customer_loyalty_ledger(shop_id);

-- Add loyalty_points column to customers if it does not exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'customers' AND column_name = 'loyalty_points'
    ) THEN
        ALTER TABLE customers ADD COLUMN loyalty_points INTEGER NOT NULL DEFAULT 0;
    END IF;
END $$;

-- 3. ENABLE RLS
ALTER TABLE loyalty_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_loyalty_ledger ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Shop members view loyalty settings" ON loyalty_settings
    FOR SELECT USING (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY "Shop owners/managers edit loyalty settings" ON loyalty_settings
    FOR ALL USING (user_has_shop_role(shop_id, ARRAY['owner'::user_role, 'manager'::user_role]));

CREATE POLICY "Shop members view loyalty ledger" ON customer_loyalty_ledger
    FOR SELECT USING (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY "Shop members insert loyalty ledger" ON customer_loyalty_ledger
    FOR INSERT WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

-- 4. RPC: Process Loyalty Transaction
CREATE OR REPLACE FUNCTION public.process_loyalty_transaction(
    p_shop_id UUID,
    p_customer_id UUID,
    p_bill_id UUID DEFAULT NULL,
    p_points_to_earn INTEGER DEFAULT 0,
    p_points_to_redeem INTEGER DEFAULT 0,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role user_role;
    v_settings RECORD;
    v_customer RECORD;
    v_current_points INTEGER := 0;
    v_net_change INTEGER := 0;
    v_new_balance INTEGER := 0;
    v_discount_paise BIGINT := 0;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT role INTO v_user_role
    FROM shop_users
    WHERE shop_id = p_shop_id AND user_id = auth.uid() AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Access Denied: Caller is not an active member of shop %', p_shop_id;
    END IF;

    SELECT * INTO v_customer
    FROM customers
    WHERE id = p_customer_id AND shop_id = p_shop_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer % not found in shop %', p_customer_id, p_shop_id;
    END IF;

    v_current_points := COALESCE(v_customer.loyalty_points, 0);

    -- Load or initialize shop loyalty settings
    SELECT * INTO v_settings FROM loyalty_settings WHERE shop_id = p_shop_id;
    IF NOT FOUND THEN
        INSERT INTO loyalty_settings (shop_id) VALUES (p_shop_id)
        RETURNING * INTO v_settings;
    END IF;

    -- Validate Redemption
    IF p_points_to_redeem > 0 THEN
        IF NOT v_settings.is_enabled THEN
            RAISE EXCEPTION 'Loyalty program is currently disabled for this shop';
        END IF;

        IF p_points_to_redeem > v_current_points THEN
            RAISE EXCEPTION 'Insufficient Points: Attempted to redeem % points, customer has % points',
                p_points_to_redeem, v_current_points;
        END IF;

        IF p_points_to_redeem < v_settings.min_points_to_redeem THEN
            RAISE EXCEPTION 'Minimum redemption threshold is % points', v_settings.min_points_to_redeem;
        END IF;

        v_discount_paise := p_points_to_redeem * v_settings.redemption_value_paise;

        -- Record Redemption Ledger
        v_current_points := v_current_points - p_points_to_redeem;
        INSERT INTO customer_loyalty_ledger (
            id, shop_id, customer_id, bill_id,
            transaction_type, points_changed, balance_after,
            notes, created_at
        ) VALUES (
            gen_random_uuid(), p_shop_id, p_customer_id, p_bill_id,
            'redeem', -p_points_to_redeem, v_current_points,
            COALESCE(p_notes, 'Redeemed on Bill'), v_now
        );
    END IF;

    -- Process Point Accrual
    IF p_points_to_earn > 0 AND v_settings.is_enabled THEN
        v_current_points := v_current_points + p_points_to_earn;
        INSERT INTO customer_loyalty_ledger (
            id, shop_id, customer_id, bill_id,
            transaction_type, points_changed, balance_after,
            notes, created_at
        ) VALUES (
            gen_random_uuid(), p_shop_id, p_customer_id, p_bill_id,
            'earn', p_points_to_earn, v_current_points,
            COALESCE(p_notes, 'Earned from Purchase'), v_now
        );
    END IF;

    -- Update Customer Record
    UPDATE customers
    SET loyalty_points = v_current_points,
        updated_at = v_now
    WHERE id = p_customer_id;

    RETURN jsonb_build_object(
        'success', true,
        'customer_id', p_customer_id,
        'points_earned', p_points_to_earn,
        'points_redeemed', p_points_to_redeem,
        'discount_paise', v_discount_paise,
        'new_points_balance', v_current_points,
        'timestamp', v_now
    );
END;
$$;

-- 5. RPC: Get Customer Loyalty Summary
CREATE OR REPLACE FUNCTION public.get_customer_loyalty_summary(
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
    v_settings RECORD;
    v_total_earned BIGINT := 0;
    v_total_redeemed BIGINT := 0;
    v_recent_txns JSONB := '[]'::jsonb;
BEGIN
    SELECT * INTO v_customer
    FROM customers
    WHERE id = p_customer_id AND shop_id = p_shop_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer % not found in shop %', p_customer_id, p_shop_id;
    END IF;

    SELECT * INTO v_settings FROM loyalty_settings WHERE shop_id = p_shop_id;
    IF NOT FOUND THEN
        SELECT TRUE as is_enabled, 1.00 as earn_rate_percentage, 100 as redemption_value_paise, 50 as min_points_to_redeem INTO v_settings;
    END IF;

    SELECT 
        COALESCE(SUM(CASE WHEN points_changed > 0 THEN points_changed ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN points_changed < 0 THEN ABS(points_changed) ELSE 0 END), 0)
    INTO v_total_earned, v_total_redeemed
    FROM customer_loyalty_ledger
    WHERE customer_id = p_customer_id AND shop_id = p_shop_id;

    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'bill_id', bill_id,
            'transaction_type', transaction_type,
            'points_changed', points_changed,
            'balance_after', balance_after,
            'notes', notes,
            'created_at', created_at
        ) ORDER BY created_at DESC
    ) INTO v_recent_txns
    FROM (
        SELECT * FROM customer_loyalty_ledger
        WHERE customer_id = p_customer_id AND shop_id = p_shop_id
        ORDER BY created_at DESC
        LIMIT 10
    ) sub;

    RETURN jsonb_build_object(
        'customer_id', p_customer_id,
        'customer_name', v_customer.name,
        'current_points', COALESCE(v_customer.loyalty_points, 0),
        'equivalent_rupees', (COALESCE(v_customer.loyalty_points, 0) * COALESCE(v_settings.redemption_value_paise, 100)) / 100.0,
        'total_lifetime_points_earned', v_total_earned,
        'total_lifetime_points_redeemed', v_total_redeemed,
        'is_program_enabled', COALESCE(v_settings.is_enabled, true),
        'recent_transactions', COALESCE(v_recent_txns, '[]'::jsonb)
    );
END;
$$;
