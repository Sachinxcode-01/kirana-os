-- ==============================================================================
-- 009: PRODUCT BARCODES ENHANCEMENT
-- Adds barcode_type and updated_at to product_barcodes table with composite indexes
-- ==============================================================================

-- 1. Add barcode_type and updated_at columns if not present
ALTER TABLE product_barcodes ADD COLUMN IF NOT EXISTS barcode_type VARCHAR(32) NOT NULL DEFAULT 'EAN_13';
ALTER TABLE product_barcodes ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- 2. Fast lookup index for sub-15ms scanner queries
CREATE INDEX IF NOT EXISTS idx_product_barcodes_shop_barcode 
ON product_barcodes(shop_id, barcode);

CREATE INDEX IF NOT EXISTS idx_product_barcodes_product_id 
ON product_barcodes(product_id);

-- 3. Ensure RLS is active on product_barcodes
ALTER TABLE product_barcodes ENABLE ROW LEVEL SECURITY;

-- 4. Re-verify RLS policies for tenant isolation
DROP POLICY IF EXISTS rls_product_barcodes_all ON product_barcodes;

CREATE POLICY rls_product_barcodes_all ON product_barcodes
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
