-- ==============================================================================
-- KIRANAOS MIGRATION 017: USER PROFILES SCHEMA & AUTOMATIC AUTH TRIGGER
-- ==============================================================================

-- 1. Create Dedicated Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(25),
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for email lookup
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- 2. Row Level Security Policies for Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'rls_profiles_select'
    ) THEN
        CREATE POLICY rls_profiles_select ON public.profiles
            FOR SELECT TO authenticated
            USING (
                id = auth.uid() 
                OR id IN (
                    SELECT user_id FROM public.shop_users 
                    WHERE shop_id IN (SELECT public.get_user_shop_ids())
                )
            );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'rls_profiles_insert'
    ) THEN
        CREATE POLICY rls_profiles_insert ON public.profiles
            FOR INSERT TO authenticated
            WITH CHECK (id = auth.uid());
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'rls_profiles_update'
    ) THEN
        CREATE POLICY rls_profiles_update ON public.profiles
            FOR UPDATE TO authenticated
            USING (id = auth.uid())
            WITH CHECK (id = auth.uid());
    END IF;
END $$;

-- 3. Automatic Profile Creation/Update Trigger on auth.users
CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
RETURNS TRIGGER AS $$
DECLARE
    v_name VARCHAR(255);
    v_phone VARCHAR(25);
    v_avatar TEXT;
BEGIN
    v_name := COALESCE(
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'display_name',
        NEW.raw_user_meta_data->>'name',
        split_part(NEW.email, '@', 1),
        'Store User'
    );
    v_phone := COALESCE(NEW.phone, NEW.raw_user_meta_data->>'phone');
    v_avatar := NEW.raw_user_meta_data->>'avatar_url';

    INSERT INTO public.profiles (
        id,
        full_name,
        email,
        phone,
        avatar_url,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        v_name,
        COALESCE(NEW.email, ''),
        v_phone,
        v_avatar,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email,
        phone = COALESCE(NULLIF(EXCLUDED.phone, ''), profiles.phone),
        avatar_url = COALESCE(EXCLUDED.avatar_url, profiles.avatar_url),
        updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Attach trigger to auth.users
DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users;
CREATE TRIGGER trg_on_auth_user_created
    AFTER INSERT OR UPDATE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user_profile();

-- 4. Helper RPC to Fetch or Ensure Profile
CREATE OR REPLACE FUNCTION public.get_or_create_user_profile(
    p_user_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_target_id UUID;
    v_profile RECORD;
BEGIN
    v_target_id := COALESCE(p_user_id, auth.uid());
    IF v_target_id IS NULL THEN
        RAISE EXCEPTION 'Authentication required to access profile';
    END IF;

    SELECT * INTO v_profile FROM public.profiles WHERE id = v_target_id;

    IF NOT FOUND THEN
        -- Attempt backfill from auth.users
        INSERT INTO public.profiles (id, full_name, email, created_at, updated_at)
        SELECT 
            u.id,
            COALESCE(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'display_name', split_part(u.email, '@', 1)),
            COALESCE(u.email, ''),
            NOW(),
            NOW()
        FROM auth.users u
        WHERE u.id = v_target_id
        ON CONFLICT (id) DO NOTHING;

        SELECT * INTO v_profile FROM public.profiles WHERE id = v_target_id;
    END IF;

    RETURN jsonb_build_object(
        'id', v_profile.id,
        'full_name', v_profile.full_name,
        'email', v_profile.email,
        'phone', v_profile.phone,
        'avatar_url', v_profile.avatar_url,
        'created_at', v_profile.created_at,
        'updated_at', v_profile.updated_at
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_or_create_user_profile TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_or_create_user_profile TO service_role;
