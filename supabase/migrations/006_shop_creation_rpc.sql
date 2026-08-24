-- ==============================================================================
-- KiranaOS — Phase 03: Migration 006: Atomic Shop & Owner Creation RPC
-- ==============================================================================

CREATE OR REPLACE FUNCTION create_shop_and_owner_membership(
    p_name VARCHAR,
    p_phone VARCHAR,
    p_address TEXT DEFAULT NULL,
    p_city VARCHAR DEFAULT NULL,
    p_state VARCHAR DEFAULT 'Karnataka',
    p_pincode VARCHAR DEFAULT NULL,
    p_gstin VARCHAR DEFAULT NULL,
    p_fssai_license VARCHAR DEFAULT NULL,
    p_upi_id VARCHAR DEFAULT NULL,
    p_logo_url TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_shop_id UUID;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to create a shop';
    END IF;

    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RAISE EXCEPTION 'Shop name cannot be empty';
    END IF;

    IF p_phone IS NULL OR TRIM(p_phone) = '' THEN
        RAISE EXCEPTION 'Shop contact phone cannot be empty';
    END IF;

    -- 1. Create shop
    v_shop_id := gen_random_uuid();
    INSERT INTO shops (
        id,
        name,
        owner_id,
        phone,
        address,
        city,
        state,
        pincode,
        gstin,
        fssai_license,
        upi_id,
        logo_url,
        currency,
        created_at,
        updated_at
    ) VALUES (
        v_shop_id,
        TRIM(p_name),
        v_user_id,
        TRIM(p_phone),
        p_address,
        p_city,
        COALESCE(p_state, 'Karnataka'),
        p_pincode,
        p_gstin,
        p_fssai_license,
        p_upi_id,
        p_logo_url,
        'INR',
        NOW(),
        NOW()
    );

    -- 2. Create owner membership in shop_users
    INSERT INTO shop_users (
        id,
        shop_id,
        user_id,
        role,
        display_name,
        status,
        created_at,
        updated_at
    ) VALUES (
        gen_random_uuid(),
        v_shop_id,
        v_user_id,
        'owner',
        TRIM(p_name) || ' Owner',
        'active',
        NOW(),
        NOW()
    );

    -- 3. Return JSON response
    RETURN jsonb_build_object(
        'status', 'SUCCESS',
        'shop_id', v_shop_id,
        'name', TRIM(p_name),
        'role', 'owner'
    );
END;
$$;
