-- ==============================================================================
-- KIRANAOS MIGRATION 018: SHOP ONBOARDING IDEMPOTENCY & OWNER MEMBERSHIP RPC
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.create_shop_and_owner_membership(
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
    v_existing_shop_id UUID;
    v_existing_shop_name VARCHAR;
    v_shop_id UUID;
BEGIN
    -- 1. Security Check: Derived strictly from authenticated Supabase session
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to create a shop';
    END IF;

    -- 2. Idempotency Check: Prevent duplicate shops from retries, double taps, or restarts
    SELECT s.id, s.name INTO v_existing_shop_id, v_existing_shop_name
    FROM public.shops s
    JOIN public.shop_users su ON su.shop_id = s.id
    WHERE su.user_id = v_user_id AND su.status = 'active'
    LIMIT 1;

    IF v_existing_shop_id IS NOT NULL THEN
        RETURN jsonb_build_object(
            'status', 'SUCCESS',
            'shop_id', v_existing_shop_id,
            'name', v_existing_shop_name,
            'is_existing', true,
            'message', 'Shop already exists for this account'
        );
    END IF;

    -- 3. Input Validation
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RAISE EXCEPTION 'Shop name cannot be empty';
    END IF;

    IF p_phone IS NULL OR TRIM(p_phone) = '' THEN
        RAISE EXCEPTION 'Shop contact phone cannot be empty';
    END IF;

    -- 4. Create Shop Record
    v_shop_id := gen_random_uuid();
    INSERT INTO public.shops (
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

    -- 5. Create Owner Membership in shop_users Table
    INSERT INTO public.shop_users (
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

    RETURN jsonb_build_object(
        'status', 'SUCCESS',
        'shop_id', v_shop_id,
        'name', TRIM(p_name),
        'is_existing', false,
        'message', 'Shop created successfully'
    );
END;
$$;

-- Grant execution permissions to authenticated users
GRANT EXECUTE ON FUNCTION public.create_shop_and_owner_membership TO authenticated;

-- Helper RPC to fetch user's active shop
CREATE OR REPLACE FUNCTION public.get_user_active_shop()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id UUID;
    v_shop_record RECORD;
BEGIN
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required';
    END IF;

    SELECT 
        s.id,
        s.name,
        s.phone,
        s.address,
        s.city,
        s.state,
        s.pincode,
        s.gstin,
        s.fssai_license,
        s.upi_id,
        s.logo_url,
        s.created_at,
        su.role
    INTO v_shop_record
    FROM public.shops s
    JOIN public.shop_users su ON su.shop_id = s.id
    WHERE su.user_id = v_user_id AND su.status = 'active'
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('has_shop', false);
    END IF;

    RETURN jsonb_build_object(
        'has_shop', true,
        'shop_id', v_shop_record.id,
        'name', v_shop_record.name,
        'phone', v_shop_record.phone,
        'address', v_shop_record.address,
        'city', v_shop_record.city,
        'state', v_shop_record.state,
        'pincode', v_shop_record.pincode,
        'role', v_shop_record.role,
        'created_at', v_shop_record.created_at
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_user_active_shop TO authenticated;
