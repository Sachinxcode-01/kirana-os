-- ==============================================================================
-- 008: PRODUCTS MASTER ENHANCEMENT
-- Adds brand, unit columns to products if missing, plus category & search indexes
-- ==============================================================================

-- 1. Add brand and unit columns if not present
ALTER TABLE products ADD COLUMN IF NOT EXISTS brand VARCHAR(100);
ALTER TABLE products ADD COLUMN IF NOT EXISTS unit VARCHAR(50) NOT NULL DEFAULT 'PCS';

-- 2. Performance indexes for multi-tenant product lookups and filtering
CREATE INDEX IF NOT EXISTS idx_products_shop_category_active 
ON products(shop_id, category_id, is_active, name);

CREATE INDEX IF NOT EXISTS idx_products_shop_name_active 
ON products(shop_id, is_active, name);

-- 3. Ensure RLS is active on products
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- 4. Re-verify RLS policies for tenant isolation
DROP POLICY IF EXISTS rls_products_all ON products;

CREATE POLICY rls_products_all ON products
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
