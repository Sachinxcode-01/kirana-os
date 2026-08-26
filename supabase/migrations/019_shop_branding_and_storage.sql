-- ==============================================================================
-- KIRANAOS MIGRATION 019: SHOP BRANDING & STORAGE BUCKET POLICIES
-- ==============================================================================

-- 1. Add receipt_name column to public.shops table
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS receipt_name VARCHAR DEFAULT NULL;

-- 2. Create Storage Bucket for Shops Branding & Media
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'shops',
    'shops',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- 3. Storage Row-Level Security Policies for 'shops' Bucket
-- Target Path Scheme: shops/{shop_id}/branding/{filename}

-- Public Read Access for Shop Logos
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Public Read Access for Shop Logos' AND tablename = 'objects'
    ) THEN
        CREATE POLICY "Public Read Access for Shop Logos"
        ON storage.objects FOR SELECT
        USING (bucket_id = 'shops');
    END IF;
END $$;

-- Shop Owners and Managers Can Upload Shop Logos
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Shop Owners and Managers Can Upload Shop Logos' AND tablename = 'objects'
    ) THEN
        CREATE POLICY "Shop Owners and Managers Can Upload Shop Logos"
        ON storage.objects FOR INSERT
        TO authenticated
        WITH CHECK (
            bucket_id = 'shops' AND
            user_has_shop_role((storage.foldername(name))[1]::UUID, ARRAY['owner'::user_role, 'manager'::user_role])
        );
    END IF;
END $$;

-- Shop Owners and Managers Can Update Shop Logos
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Shop Owners and Managers Can Update Shop Logos' AND tablename = 'objects'
    ) THEN
        CREATE POLICY "Shop Owners and Managers Can Update Shop Logos"
        ON storage.objects FOR UPDATE
        TO authenticated
        USING (
            bucket_id = 'shops' AND
            user_has_shop_role((storage.foldername(name))[1]::UUID, ARRAY['owner'::user_role, 'manager'::user_role])
        )
        WITH CHECK (
            bucket_id = 'shops' AND
            user_has_shop_role((storage.foldername(name))[1]::UUID, ARRAY['owner'::user_role, 'manager'::user_role])
        );
    END IF;
END $$;

-- Shop Owners and Managers Can Delete Shop Logos
DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'Shop Owners and Managers Can Delete Shop Logos' AND tablename = 'objects'
    ) THEN
        CREATE POLICY "Shop Owners and Managers Can Delete Shop Logos"
        ON storage.objects FOR DELETE
        TO authenticated
        USING (
            bucket_id = 'shops' AND
            user_has_shop_role((storage.foldername(name))[1]::UUID, ARRAY['owner'::user_role, 'manager'::user_role])
        );
    END IF;
END $$;
