-- ==============================================================================
-- KiranaOS — Phase 13.0: Migration 024: Product Catalog Foundation Enhancements
-- Adds SKU column to products table and composite index for multi-tenant search
-- ==============================================================================

-- 1. Add SKU column to products if missing
ALTER TABLE products ADD COLUMN IF NOT EXISTS sku VARCHAR(100);

-- 2. Performance index for shop-scoped SKU lookups
CREATE INDEX IF NOT EXISTS idx_products_shop_sku 
ON products(shop_id, sku) 
WHERE sku IS NOT NULL;

-- 3. Additional search composite index for fast name, category and barcode queries
CREATE INDEX IF NOT EXISTS idx_products_shop_active_search 
ON products(shop_id, is_active, name);
