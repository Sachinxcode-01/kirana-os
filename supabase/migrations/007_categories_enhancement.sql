-- ==============================================================================
-- 007: CATEGORIES ENHANCEMENT & REFINEMENT
-- Adds description, is_active flag, and composite indexes for fast catalog lookups
-- ==============================================================================

-- 1. Add description and is_active columns if not present
ALTER TABLE categories ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE categories ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- 2. Performance indexes for multi-tenant category lookups
CREATE INDEX IF NOT EXISTS idx_categories_shop_active_sort 
ON categories(shop_id, is_active, sort_order, name);

CREATE INDEX IF NOT EXISTS idx_categories_shop_name 
ON categories(shop_id, name);

-- 3. Ensure RLS is active on categories
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- 4. Re-verify RLS policies for tenant isolation
DROP POLICY IF EXISTS rls_categories_all ON categories;

CREATE POLICY rls_categories_all ON categories
    FOR ALL
    TO authenticated
    USING (
        shop_id IN (
            SELECT shop_id FROM shop_users 
            WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        shop_id IN (
            SELECT shop_id FROM shop_users 
            WHERE user_id = auth.uid() 
            AND role IN ('owner', 'manager')
        )
    );
