-- ==============================================================================
-- KiranaOS — Phase 02: Migration 005: Storage Buckets & Media Policies
-- Supabase Storage Configuration & Tenant-Isolated Image Upload Policies
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. CREATE STORAGE BUCKET
-- ------------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'products',
    'products',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- ------------------------------------------------------------------------------
-- 2. STORAGE ROW-LEVEL SECURITY POLICIES
-- Target Path Scheme: products/{shop_id}/{product_id}/{filename}
-- ------------------------------------------------------------------------------

-- Allow public read access to product images
CREATE POLICY "Public Read Access for Product Images"
ON storage.objects FOR SELECT
USING (bucket_id = 'products');

-- Allow authenticated shop staff to upload product images within their shop folder
CREATE POLICY "Shop Staff Can Upload Product Images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'products' AND
    (storage.foldername(name))[1]::UUID IN (SELECT get_user_shop_ids())
);

-- Allow authenticated shop staff to update/replace product images within their shop folder
CREATE POLICY "Shop Staff Can Update Product Images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'products' AND
    (storage.foldername(name))[1]::UUID IN (SELECT get_user_shop_ids())
)
WITH CHECK (
    bucket_id = 'products' AND
    (storage.foldername(name))[1]::UUID IN (SELECT get_user_shop_ids())
);

-- Allow shop owners/managers to delete product images within their shop folder
CREATE POLICY "Shop Owners and Managers Can Delete Product Images"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'products' AND
    user_has_shop_role((storage.foldername(name))[1]::UUID, ARRAY['owner'::user_role, 'manager'::user_role])
);
