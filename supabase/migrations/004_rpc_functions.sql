-- ==============================================================================
-- KiranaOS — Phase 02: Migration 004: Server-Side RPC Functions
-- Atomic Server Transactions, Sync Ingestion Batching & Idempotency Handlers
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. ATOMIC BILL CREATION WITH STOCK DECREMENT
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_bill_atomic(
    p_bill JSONB,
    p_items JSONB,
    p_payments JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_shop_id UUID;
    v_bill_id UUID;
    v_bill_number VARCHAR;
    v_item JSONB;
    v_payment JSONB;
    v_product_id UUID;
    v_qty NUMERIC;
    v_current_stock NUMERIC;
    v_new_stock NUMERIC;
BEGIN
    v_shop_id := (p_bill->>'shop_id')::UUID;

    -- Security Check: Caller must belong to the target shop
    IF NOT EXISTS (
        SELECT 1 FROM shop_users 
        WHERE shop_id = v_shop_id AND user_id = auth.uid() AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'Access Denied: Not an active member of shop %', v_shop_id;
    END IF;

    -- Insert or fetch bill idempotently
    v_bill_id := COALESCE((p_bill->>'id')::UUID, gen_random_uuid());
    v_bill_number := p_bill->>'bill_number';

    INSERT INTO bills (
        id, shop_id, bill_number, customer_id, cashier_id,
        subtotal_paise, tax_total_paise, discount_paise, total_paise,
        payment_status, created_at, updated_at
    ) VALUES (
        v_bill_id,
        v_shop_id,
        v_bill_number,
        (p_bill->>'customer_id')::UUID,
        auth.uid(),
        (p_bill->>'subtotal_paise')::BIGINT,
        COALESCE((p_bill->>'tax_total_paise')::BIGINT, 0),
        COALESCE((p_bill->>'discount_paise')::BIGINT, 0),
        (p_bill->>'total_paise')::BIGINT,
        COALESCE(p_bill->>'payment_status', 'paid'),
        COALESCE((p_bill->>'created_at')::TIMESTAMPTZ, NOW()),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;

    -- Insert bill items and adjust stock
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item->>'product_id')::UUID;
        v_qty := (v_item->>'quantity')::NUMERIC;

        INSERT INTO bill_items (
            id, bill_id, product_id, product_name, quantity,
            unit_price_paise, tax_rate, tax_amount_paise, total_paise, created_at
        ) VALUES (
            COALESCE((v_item->>'id')::UUID, gen_random_uuid()),
            v_bill_id,
            v_product_id,
            v_item->>'product_name',
            v_qty,
            (v_item->>'unit_price_paise')::BIGINT,
            COALESCE((v_item->>'tax_rate')::NUMERIC, 0.00),
            COALESCE((v_item->>'tax_amount_paise')::BIGINT, 0),
            (v_item->>'total_paise')::BIGINT,
            COALESCE((v_item->>'created_at')::TIMESTAMPTZ, NOW())
        )
        ON CONFLICT (id) DO NOTHING;

        -- Stock decrement and movement ledger
        SELECT current_stock INTO v_current_stock 
        FROM products 
        WHERE id = v_product_id FOR UPDATE;

        IF FOUND THEN
            v_new_stock := v_current_stock - v_qty;
            UPDATE products SET current_stock = v_new_stock, updated_at = NOW() WHERE id = v_product_id;

            INSERT INTO inventory_movements (
                shop_id, product_id, quantity_delta, balance_after,
                reason, reference_id, performed_by, created_at
            ) VALUES (
                v_shop_id,
                v_product_id,
                -v_qty,
                v_new_stock,
                'sale'::movement_reason,
                v_bill_id,
                auth.uid(),
                NOW()
            );
        END IF;
    END LOOP;

    -- Insert payments
    FOR v_payment IN SELECT * FROM jsonb_array_elements(p_payments)
    LOOP
        INSERT INTO payments (
            id, shop_id, bill_id, mode, amount_paise, reference_number, created_at
        ) VALUES (
            COALESCE((v_payment->>'id')::UUID, gen_random_uuid()),
            v_shop_id,
            v_bill_id,
            (v_payment->>'mode')::payment_mode,
            (v_payment->>'amount_paise')::BIGINT,
            v_payment->>'reference_number',
            COALESCE((v_payment->>'created_at')::TIMESTAMPTZ, NOW())
        )
        ON CONFLICT (id) DO NOTHING;
    END LOOP;

    RETURN jsonb_build_object(
        'status', 'SUCCESS',
        'bill_id', v_bill_id,
        'bill_number', v_bill_number
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 2. ATOMIC CREDIT (KHATA) TRANSACTION & BALANCE UPDATE
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION record_credit_transaction_atomic(
    p_shop_id UUID,
    p_customer_id UUID,
    p_amount_paise BIGINT,
    p_type credit_txn_type,
    p_bill_id UUID DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_txn_id UUID;
    v_current_debt BIGINT;
    v_new_debt BIGINT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM shop_users 
        WHERE shop_id = p_shop_id AND user_id = auth.uid() AND status = 'active'
    ) THEN
        RAISE EXCEPTION 'Access Denied: Not an active member of shop %', p_shop_id;
    END IF;

    SELECT current_debt_paise INTO v_current_debt
    FROM customers
    WHERE id = p_customer_id AND shop_id = p_shop_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer % not found in shop %', p_customer_id, p_shop_id;
    END IF;

    IF p_type = 'credit_given'::credit_txn_type THEN
        v_new_debt := v_current_debt + p_amount_paise;
    ELSIF p_type = 'payment_received'::credit_txn_type OR p_type = 'bad_debt_writeoff'::credit_txn_type THEN
        v_new_debt := GREATEST(0, v_current_debt - p_amount_paise);
    END IF;

    UPDATE customers 
    SET current_debt_paise = v_new_debt, updated_at = NOW() 
    WHERE id = p_customer_id;

    v_txn_id := gen_random_uuid();
    INSERT INTO credit_transactions (
        id, shop_id, customer_id, bill_id, amount_paise, type, notes, recorded_by, created_at
    ) VALUES (
        v_txn_id, p_shop_id, p_customer_id, p_bill_id, p_amount_paise, p_type, p_notes, auth.uid(), NOW()
    );

    RETURN jsonb_build_object(
        'status', 'SUCCESS',
        'transaction_id', v_txn_id,
        'new_debt_paise', v_new_debt
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 3. OFFLINE BATCH SYNC INGESTION (Deterministic Idempotency Handler)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION process_sync_batch(
    p_operations JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_op JSONB;
    v_op_id UUID;
    v_shop_id UUID;
    v_entity_type VARCHAR;
    v_op_type VARCHAR;
    v_payload JSONB;
    v_results JSONB := '[]'::JSONB;
BEGIN
    FOR v_op IN SELECT * FROM jsonb_array_elements(p_operations)
    LOOP
        v_op_id := (v_op->>'operation_id')::UUID;
        v_shop_id := (v_op->>'shop_id')::UUID;
        v_entity_type := v_op->>'entity_type';
        v_op_type := v_op->>'operation_type';
        v_payload := v_op->'payload';

        -- Verify shop access
        IF NOT EXISTS (
            SELECT 1 FROM shop_users 
            WHERE shop_id = v_shop_id AND user_id = auth.uid() AND status = 'active'
        ) THEN
            v_results := v_results || jsonb_build_object(
                'operation_id', v_op_id,
                'status', 'FAILED',
                'error', 'Unauthorized shop access'
            );
            CONTINUE;
        END IF;

        -- Idempotency check: If operation was already ingested, acknowledge without duplicate processing
        IF EXISTS (SELECT 1 FROM sync_operations WHERE operation_id = v_op_id) THEN
            v_results := v_results || jsonb_build_object(
                'operation_id', v_op_id,
                'status', 'SYNCED',
                'idempotent_duplicate', true
            );
            CONTINUE;
        END IF;

        -- Record operation in sync ledger
        INSERT INTO sync_operations (
            operation_id, shop_id, entity_type, operation_type,
            client_timestamp, server_timestamp, payload, processed_status
        ) VALUES (
            v_op_id, v_shop_id, v_entity_type, v_op_type,
            (v_op->>'client_timestamp')::TIMESTAMPTZ, NOW(), v_payload, 'SYNCED'::sync_status_type
        );

        -- Execute entity mutation based on type
        IF v_entity_type = 'bill' THEN
            PERFORM create_bill_atomic(
                v_payload->'bill',
                v_payload->'items',
                COALESCE(v_payload->'payments', '[]'::JSONB)
            );
        ELSIF v_entity_type = 'customer' THEN
            INSERT INTO customers (
                id, shop_id, name, phone, address, credit_limit_paise, current_debt_paise, created_at, updated_at
            ) VALUES (
                (v_payload->>'id')::UUID,
                v_shop_id,
                v_payload->>'name',
                v_payload->>'phone',
                v_payload->>'address',
                COALESCE((v_payload->>'credit_limit_paise')::BIGINT, 500000),
                COALESCE((v_payload->>'current_debt_paise')::BIGINT, 0),
                COALESCE((v_payload->>'created_at')::TIMESTAMPTZ, NOW()),
                NOW()
            )
            ON CONFLICT (id) DO UPDATE SET
                name = EXCLUDED.name,
                phone = EXCLUDED.phone,
                address = EXCLUDED.address,
                credit_limit_paise = EXCLUDED.credit_limit_paise,
                updated_at = NOW();
        END IF;

        v_results := v_results || jsonb_build_object(
            'operation_id', v_op_id,
            'status', 'SYNCED'
        );
    END LOOP;

    RETURN v_results;
END;
$$;
