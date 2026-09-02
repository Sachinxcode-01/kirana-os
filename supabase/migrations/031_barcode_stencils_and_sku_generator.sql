-- ==============================================================================
-- KiranaOS — Phase 15: Migration 031: Barcode Stencils & In-Store SKU Generator
-- Standard EAN-13 GS1 Mod-10 Generator, Weight-Embedded Barcodes, Print Jobs Queue
-- ==============================================================================

-- 1. EXTEND PRODUCTS TABLE
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'internal_sku') THEN
        ALTER TABLE products ADD COLUMN internal_sku VARCHAR(50);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'is_loose_item') THEN
        ALTER TABLE products ADD COLUMN is_loose_item BOOLEAN NOT NULL DEFAULT FALSE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'barcode_label_template') THEN
        ALTER TABLE products ADD COLUMN barcode_label_template VARCHAR(50) NOT NULL DEFAULT 'roll_50x25';
    END IF;
END $$;

-- 2. BARCODE PRINT JOBS TABLE
CREATE TABLE IF NOT EXISTS barcode_print_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    template_format VARCHAR(50) NOT NULL DEFAULT 'roll_50x25',
    status VARCHAR(20) NOT NULL DEFAULT 'queued', -- 'queued', 'printing', 'completed', 'cancelled'
    items JSONB NOT NULL,
    total_labels INTEGER NOT NULL DEFAULT 1,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_print_jobs_shop ON barcode_print_jobs(shop_id, created_at DESC);

ALTER TABLE barcode_print_jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Shop members manage barcode print jobs" ON barcode_print_jobs
    FOR ALL USING (shop_id IN (SELECT get_user_shop_ids()));

-- 3. FUNCTION: Compute GS1 Mod-10 EAN-13 Check Digit
CREATE OR REPLACE FUNCTION public.compute_ean13_check_digit(p_12_digits TEXT)
RETURNS INTEGER
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_sum INTEGER := 0;
    v_digit INTEGER;
    v_i INTEGER;
    v_mod INTEGER;
BEGIN
    IF LENGTH(p_12_digits) != 12 THEN
        RAISE EXCEPTION 'Input must be exactly 12 numeric digits, got: %', p_12_digits;
    END IF;

    FOR v_i IN 1..12 LOOP
        v_digit := SUBSTRING(p_12_digits FROM v_i FOR 1)::integer;
        IF v_i % 2 = 1 THEN
            -- Odd positions (1st, 3rd, 5th...) weight = 1
            v_sum := v_sum + v_digit;
        ELSE
            -- Even positions (2nd, 4th, 6th...) weight = 3
            v_sum := v_sum + (v_digit * 3);
        END IF;
    END LOOP;

    v_mod := v_sum % 10;
    IF v_mod = 0 THEN
        RETURN 0;
    ELSE
        RETURN 10 - v_mod;
    END IF;
END;
$$;

-- 4. RPC: Generate In-Store EAN-13 Barcode
CREATE OR REPLACE FUNCTION public.generate_in_store_barcode(
    p_shop_id UUID,
    p_product_id UUID,
    p_prefix TEXT DEFAULT '20', -- Standard in-store retail prefix '20' - '29'
    p_is_weight_embedded BOOLEAN DEFAULT FALSE,
    p_weight_grams INTEGER DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role user_role;
    v_product RECORD;
    v_seq_num BIGINT;
    v_base_12 TEXT;
    v_check_digit INTEGER;
    v_full_barcode TEXT;
    v_sku TEXT;
    v_now TIMESTAMPTZ := NOW();
BEGIN
    SELECT role INTO v_user_role
    FROM shop_users
    WHERE shop_id = p_shop_id AND user_id = auth.uid() AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Access Denied: Caller is not an active member of shop %', p_shop_id;
    END IF;

    SELECT * INTO v_product
    FROM products
    WHERE id = p_product_id AND shop_id = p_shop_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Product % not found in shop %', p_product_id, p_shop_id;
    END IF;

    -- Generate sequence or derive from product sequence
    SELECT COALESCE(COUNT(*), 0) + 1 INTO v_seq_num
    FROM product_barcodes
    WHERE shop_id = p_shop_id;

    IF p_is_weight_embedded THEN
        -- Format: [2 digits prefix] + [5 digits item sku] + [5 digits weight in grams] = 12 digits
        v_sku := LPAD((v_seq_num % 100000)::text, 5, '0');
        v_base_12 := SUBSTRING(p_prefix FROM 1 FOR 2) || v_sku || LPAD((p_weight_grams % 100000)::text, 5, '0');
    ELSE
        -- Format: [2 digits prefix] + [10 digits sequential SKU/Item ID] = 12 digits
        v_base_12 := SUBSTRING(p_prefix FROM 1 FOR 2) || LPAD((v_seq_num % 10000000000)::text, 10, '0');
    END IF;

    -- Calculate check digit
    v_check_digit := compute_ean13_check_digit(v_base_12);
    v_full_barcode := v_base_12 || v_check_digit::text;

    -- Register barcode in product_barcodes
    INSERT INTO product_barcodes (
        id, shop_id, product_id, barcode, barcode_type, is_primary, created_at
    ) VALUES (
        gen_random_uuid(), p_shop_id, p_product_id, v_full_barcode, 'EAN_13', FALSE, v_now
    )
    ON CONFLICT (shop_id, barcode) DO NOTHING;

    -- Update product internal_sku if empty
    IF v_product.internal_sku IS NULL THEN
        UPDATE products
        SET internal_sku = 'SKU-' || LPAD(v_seq_num::text, 6, '0'),
            updated_at = v_now
        WHERE id = p_product_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'product_id', p_product_id,
        'product_name', v_product.name,
        'barcode', v_full_barcode,
        'barcode_type', 'EAN_13',
        'is_weight_embedded', p_is_weight_embedded,
        'weight_grams', p_weight_grams,
        'created_at', v_now
    );
END;
$$;

-- 5. RPC: Queue Barcode Print Job
CREATE OR REPLACE FUNCTION public.queue_barcode_print_job(
    p_shop_id UUID,
    p_items JSONB,
    p_template VARCHAR DEFAULT 'roll_50x25'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role user_role;
    v_job_id UUID := gen_random_uuid();
    v_total_labels INTEGER := 0;
    v_item JSONB;
BEGIN
    SELECT role INTO v_user_role
    FROM shop_users
    WHERE shop_id = p_shop_id AND user_id = auth.uid() AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Access Denied: Caller is not an active member of shop %', p_shop_id;
    END IF;

    IF jsonb_typeof(p_items) != 'array' THEN
        RAISE EXCEPTION 'Invalid Items: p_items must be a JSON array';
    END IF;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_total_labels := v_total_labels + COALESCE((v_item->>'copies')::integer, 1);
    END LOOP;

    INSERT INTO barcode_print_jobs (
        id, shop_id, template_format, status,
        items, total_labels, created_by, created_at, updated_at
    ) VALUES (
        v_job_id, p_shop_id, p_template, 'queued',
        p_items, v_total_labels, auth.uid(), NOW(), NOW()
    );

    RETURN jsonb_build_object(
        'success', true,
        'job_id', v_job_id,
        'shop_id', p_shop_id,
        'template_format', p_template,
        'total_labels', v_total_labels,
        'status', 'queued'
    );
END;
$$;
