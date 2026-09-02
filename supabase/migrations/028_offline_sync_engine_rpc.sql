-- ==============================================================================
-- KiranaOS — Phase 14: Migration 028: Server-Authoritative Offline 2-Way Sync Engine RPC
-- Atomic batch mutation ingestion with deterministic UUID idempotency,
-- conflict resolution (LWW / additive stock deltas), and real-time status ACKs
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.sync_client_mutation_batch(
    p_shop_id UUID,
    p_operations JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role user_role;
    v_op JSONB;
    v_op_id UUID;
    v_entity_type TEXT;
    v_entity_id UUID;
    v_op_type TEXT;
    v_payload JSONB;
    v_client_ts TIMESTAMPTZ;
    v_server_ts TIMESTAMPTZ := NOW();
    v_results JSONB := '[]'::jsonb;
    v_status sync_status_type;
    v_error_msg TEXT;
    v_existing_op RECORD;

    -- Bill Processing Variables
    v_bill_id UUID;
    v_bill_number VARCHAR(50);
    v_cashier_id UUID;
    v_customer_id UUID;
    v_subtotal BIGINT;
    v_tax BIGINT;
    v_discount BIGINT;
    v_total BIGINT;
    v_round_off BIGINT;
    v_final_amount BIGINT;
    v_payment_mode payment_mode;
    v_item JSONB;
    v_item_prod_id UUID;
    v_item_qty NUMERIC(12,3);
    v_item_unit_price BIGINT;
    v_item_tax BIGINT;
    v_item_total BIGINT;
    v_item_cost_price BIGINT;
    v_curr_stock NUMERIC(12,3);

    -- Customer & Credit Variables
    v_cust_name VARCHAR(255);
    v_cust_phone VARCHAR(20);
    v_cust_balance BIGINT;
    v_credit_amount BIGINT;
    v_credit_type credit_txn_type;

    -- Inventory Adjustment Variables
    v_adj_prod_id UUID;
    v_adj_qty NUMERIC(12,3);
    v_adj_reason movement_reason;
    v_adj_notes TEXT;

    -- Expense Variables
    v_exp_cat_id UUID;
    v_exp_amount BIGINT;
    v_exp_title VARCHAR(255);
    v_exp_notes TEXT;
BEGIN
    -- 1. Security Check: Caller must belong to the active shop
    SELECT role INTO v_user_role
    FROM shop_users
    WHERE shop_id = p_shop_id AND user_id = auth.uid() AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Access Denied: Caller is not an active member of shop %', p_shop_id;
    END IF;

    -- 2. Validate input array
    IF jsonb_typeof(p_operations) != 'array' THEN
        RAISE EXCEPTION 'Invalid Input: p_operations must be a JSON array';
    END IF;

    -- 3. Iterate over each client mutation operation
    FOR v_op IN SELECT * FROM jsonb_array_elements(p_operations)
    LOOP
        v_status := 'SYNCED';
        v_error_msg := NULL;
        
        BEGIN
            v_op_id := (v_op->>'operation_id')::uuid;
            v_entity_type := v_op->>'entity_type';
            v_entity_id := (v_op->>'entity_id')::uuid;
            v_op_type := UPPER(COALESCE(v_op->>'operation_type', 'CREATE'));
            v_payload := v_op->'payload';
            v_client_ts := COALESCE((v_op->>'client_timestamp')::timestamptz, v_server_ts);

            -- Check Idempotency: Has this operation already been processed?
            SELECT * INTO v_existing_op
            FROM sync_operations
            WHERE operation_id = v_op_id;

            IF FOUND THEN
                -- Already processed, return ACK with DUPLICATE_SKIPPED status
                v_results := v_results || jsonb_build_object(
                    'operation_id', v_op_id,
                    'entity_type', v_entity_type,
                    'entity_id', v_entity_id,
                    'status', 'DUPLICATE_SKIPPED',
                    'server_timestamp', v_existing_op.server_timestamp,
                    'error_message', NULL
                );
                CONTINUE;
            END IF;

            -- -------------------------------------------------------------
            -- ENTITY DISPATCH & CONFLICT RESOLUTION
            -- -------------------------------------------------------------
            IF v_entity_type = 'bill' THEN
                -- Extract Bill Details
                v_bill_id := COALESCE((v_payload->>'id')::uuid, v_entity_id);
                v_bill_number := v_payload->>'bill_number';
                v_cashier_id := (v_payload->>'cashier_id')::uuid;
                v_customer_id := (v_payload->>'customer_id')::uuid;
                v_subtotal := COALESCE((v_payload->>'subtotal_paise')::bigint, 0);
                v_tax := COALESCE((v_payload->>'tax_paise')::bigint, 0);
                v_discount := COALESCE((v_payload->>'discount_paise')::bigint, 0);
                v_total := COALESCE((v_payload->>'total_paise')::bigint, 0);
                v_round_off := COALESCE((v_payload->>'round_off_paise')::bigint, 0);
                v_final_amount := COALESCE((v_payload->>'final_amount_paise')::bigint, v_total);
                v_payment_mode := (v_payload->>'payment_mode')::payment_mode;

                -- Idempotent Insert Bill Header
                INSERT INTO bills (
                    id, shop_id, bill_number, cashier_id, customer_id,
                    subtotal_paise, tax_paise, discount_paise, total_paise,
                    round_off_paise, final_amount_paise, payment_mode,
                    status, created_at, updated_at
                ) VALUES (
                    v_bill_id, p_shop_id, v_bill_number, v_cashier_id, v_customer_id,
                    v_subtotal, v_tax, v_discount, v_total,
                    v_round_off, v_final_amount, v_payment_mode,
                    'completed', v_client_ts, v_server_ts
                )
                ON CONFLICT (id) DO NOTHING;

                -- Ingest Bill Items & Decrement Stock (Additive Delta)
                IF v_payload ? 'items' AND jsonb_typeof(v_payload->'items') = 'array' THEN
                    FOR v_item IN SELECT * FROM jsonb_array_elements(v_payload->'items')
                    LOOP
                        v_item_prod_id := (v_item->>'product_id')::uuid;
                        v_item_qty := (v_item->>'quantity')::numeric(12,3);
                        v_item_unit_price := (v_item->>'unit_price_paise')::bigint;
                        v_item_tax := COALESCE((v_item->>'tax_amount_paise')::bigint, 0);
                        v_item_total := (v_item->>'total_paise')::bigint;
                        v_item_cost_price := COALESCE((v_item->>'purchase_price_paise')::bigint, 0);

                        -- Insert Bill Item
                        INSERT INTO bill_items (
                            id, bill_id, product_id, product_name,
                            quantity, unit_price_paise, discount_paise,
                            tax_rate, tax_amount_paise, total_paise,
                            cost_price_paise, created_at
                        ) VALUES (
                            COALESCE((v_item->>'id')::uuid, gen_random_uuid()),
                            v_bill_id, v_item_prod_id, COALESCE(v_item->>'product_name', 'Item'),
                            v_item_qty, v_item_unit_price, COALESCE((v_item->>'discount_paise')::bigint, 0),
                            COALESCE((v_item->>'tax_rate')::numeric(5,2), 0.00), v_item_tax, v_item_total,
                            v_item_cost_price, v_client_ts
                        )
                        ON CONFLICT (id) DO NOTHING;

                        -- Apply Stock Delta & Record Movement
                        SELECT current_stock INTO v_curr_stock FROM products WHERE id = v_item_prod_id;
                        IF FOUND THEN
                            UPDATE products
                            SET current_stock = current_stock - v_item_qty,
                                updated_at = v_server_ts
                            WHERE id = v_item_prod_id;

                            INSERT INTO inventory_movements (
                                id, shop_id, product_id, quantity,
                                previous_stock, new_stock, reason,
                                reference_id, reference_type, actor_id, created_at
                            ) VALUES (
                                gen_random_uuid(), p_shop_id, v_item_prod_id, -v_item_qty,
                                v_curr_stock, v_curr_stock - v_item_qty, 'sale',
                                v_bill_id, 'bill', auth.uid(), v_client_ts
                            );
                        END IF;
                    END LOOP;
                END IF;

                -- Ingest Payments
                IF v_payload ? 'payments' AND jsonb_typeof(v_payload->'payments') = 'array' THEN
                    FOR v_item IN SELECT * FROM jsonb_array_elements(v_payload->'payments')
                    LOOP
                        INSERT INTO payments (
                            id, shop_id, bill_id, payment_mode,
                            amount_paise, status, reference_number,
                            collected_by, created_at
                        ) VALUES (
                            COALESCE((v_item->>'id')::uuid, gen_random_uuid()),
                            p_shop_id, v_bill_id, (v_item->>'payment_mode')::payment_mode,
                            (v_item->>'amount_paise')::bigint, 'success',
                            v_item->>'reference_number', auth.uid(), v_client_ts
                        )
                        ON CONFLICT (id) DO NOTHING;
                    END LOOP;
                ELSE
                    -- Single primary payment fallback
                    INSERT INTO payments (
                        id, shop_id, bill_id, payment_mode,
                        amount_paise, status, reference_number,
                        collected_by, created_at
                    ) VALUES (
                        gen_random_uuid(), p_shop_id, v_bill_id, v_payment_mode,
                        v_final_amount, 'success', v_payload->>'reference_number',
                        auth.uid(), v_client_ts
                    )
                    ON CONFLICT DO NOTHING;
                END IF;

                -- If paid via Credit / Khata, register Khata Ledger debit
                IF v_payment_mode = 'credit_khata' AND v_customer_id IS NOT NULL THEN
                    INSERT INTO credit_transactions (
                        id, shop_id, customer_id, bill_id,
                        transaction_type, amount_paise, notes,
                        created_by, created_at
                    ) VALUES (
                        gen_random_uuid(), p_shop_id, v_customer_id, v_bill_id,
                        'credit_given', v_final_amount, 'Sale Bill: ' || v_bill_number,
                        auth.uid(), v_client_ts
                    );

                    UPDATE customers
                    SET current_balance_paise = current_balance_paise + v_final_amount,
                        updated_at = v_server_ts
                    WHERE id = v_customer_id;
                END IF;

            ELSIF v_entity_type = 'customer' THEN
                v_cust_name := v_payload->>'name';
                v_cust_phone := v_payload->>'phone';
                
                INSERT INTO customers (
                    id, shop_id, name, phone, email, address,
                    credit_limit_paise, current_balance_paise,
                    created_at, updated_at
                ) VALUES (
                    v_entity_id, p_shop_id, v_cust_name, v_cust_phone,
                    v_payload->>'email', v_payload->>'address',
                    COALESCE((v_payload->>'credit_limit_paise')::bigint, 0),
                    COALESCE((v_payload->>'current_balance_paise')::bigint, 0),
                    v_client_ts, v_server_ts
                )
                ON CONFLICT (id) DO UPDATE
                SET name = EXCLUDED.name,
                    phone = EXCLUDED.phone,
                    email = COALESCE(EXCLUDED.email, customers.email),
                    address = COALESCE(EXCLUDED.address, customers.address),
                    credit_limit_paise = EXCLUDED.credit_limit_paise,
                    updated_at = v_server_ts
                WHERE customers.updated_at <= v_client_ts; -- LWW

            ELSIF v_entity_type = 'credit_transaction' THEN
                v_customer_id := (v_payload->>'customer_id')::uuid;
                v_credit_type := (v_payload->>'transaction_type')::credit_txn_type;
                v_credit_amount := (v_payload->>'amount_paise')::bigint;

                INSERT INTO credit_transactions (
                    id, shop_id, customer_id, bill_id,
                    transaction_type, amount_paise, notes,
                    created_by, created_at
                ) VALUES (
                    v_entity_id, p_shop_id, v_customer_id,
                    (v_payload->>'bill_id')::uuid,
                    v_credit_type, v_credit_amount,
                    v_payload->>'notes', auth.uid(), v_client_ts
                )
                ON CONFLICT (id) DO NOTHING;

                -- Update Customer Balance
                IF v_credit_type = 'credit_given' THEN
                    UPDATE customers
                    SET current_balance_paise = current_balance_paise + v_credit_amount,
                        updated_at = v_server_ts
                    WHERE id = v_customer_id;
                ELSIF v_credit_type IN ('payment_received', 'bad_debt_writeoff') THEN
                    UPDATE customers
                    SET current_balance_paise = current_balance_paise - v_credit_amount,
                        updated_at = v_server_ts
                    WHERE id = v_customer_id;
                END IF;

            ELSIF v_entity_type = 'inventory_adjustment' THEN
                v_adj_prod_id := (v_payload->>'product_id')::uuid;
                v_adj_qty := (v_payload->>'quantity')::numeric(12,3);
                v_adj_reason := COALESCE((v_payload->>'reason')::movement_reason, 'stock_adjustment');
                v_adj_notes := v_payload->>'notes';

                SELECT current_stock INTO v_curr_stock FROM products WHERE id = v_adj_prod_id;
                IF FOUND THEN
                    UPDATE products
                    SET current_stock = current_stock + v_adj_qty,
                        updated_at = v_server_ts
                    WHERE id = v_adj_prod_id;

                    INSERT INTO inventory_movements (
                        id, shop_id, product_id, quantity,
                        previous_stock, new_stock, reason,
                        notes, actor_id, created_at
                    ) VALUES (
                        v_entity_id, p_shop_id, v_adj_prod_id, v_adj_qty,
                        v_curr_stock, v_curr_stock + v_adj_qty, v_adj_reason,
                        v_adj_notes, auth.uid(), v_client_ts
                    )
                    ON CONFLICT (id) DO NOTHING;
                END IF;

            ELSIF v_entity_type = 'expense' THEN
                v_exp_cat_id := (v_payload->>'category_id')::uuid;
                v_exp_amount := (v_payload->>'amount_paise')::bigint;
                v_exp_title := v_payload->>'title';
                v_exp_notes := v_payload->>'notes';

                INSERT INTO expenses (
                    id, shop_id, category_id, title,
                    amount_paise, payment_mode, notes,
                    recorded_by, created_at
                ) VALUES (
                    v_entity_id, p_shop_id, v_exp_cat_id, v_exp_title,
                    v_exp_amount, COALESCE((v_payload->>'payment_mode')::payment_mode, 'cash'),
                    v_exp_notes, auth.uid(), v_client_ts
                )
                ON CONFLICT (id) DO NOTHING;

            ELSE
                v_status := 'FAILED';
                v_error_msg := 'Unsupported entity_type: ' || v_entity_type;
            END IF;

            -- 4. Record Operation Ingestion Log
            INSERT INTO sync_operations (
                operation_id, shop_id, entity_type, operation_type,
                client_timestamp, server_timestamp, payload,
                processed_status, error_message
            ) VALUES (
                v_op_id, p_shop_id, v_entity_type, v_op_type,
                v_client_ts, v_server_ts, v_payload,
                v_status, v_error_msg
            );

        EXCEPTION WHEN OTHERS THEN
            v_status := 'FAILED';
            v_error_msg := SQLERRM;

            -- Record Failure Log
            INSERT INTO sync_operations (
                operation_id, shop_id, entity_type, operation_type,
                client_timestamp, server_timestamp, payload,
                processed_status, error_message
            ) VALUES (
                v_op_id, p_shop_id, COALESCE(v_entity_type, 'unknown'), COALESCE(v_op_type, 'CREATE'),
                COALESCE(v_client_ts, v_server_ts), v_server_ts, COALESCE(v_payload, '{}'::jsonb),
                'FAILED', v_error_msg
            )
            ON CONFLICT (operation_id) DO UPDATE
            SET processed_status = 'FAILED', error_message = EXCLUDED.error_message;
        END;

        -- Accumulate Output ACK
        v_results := v_results || jsonb_build_object(
            'operation_id', v_op_id,
            'entity_type', v_entity_type,
            'entity_id', v_entity_id,
            'status', v_status,
            'server_timestamp', v_server_ts,
            'error_message', v_error_msg
        );
    END LOOP;

    RETURN jsonb_build_object(
        'success', true,
        'shop_id', p_shop_id,
        'server_timestamp', v_server_ts,
        'total_processed', jsonb_array_length(v_results),
        'results', v_results
    );
END;
$$;
