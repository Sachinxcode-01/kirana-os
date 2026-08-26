-- ==============================================================================
-- KIRANAOS MIGRATION 013: PURCHASE HISTORY COMPOSITE INDEXES & PERFORMANCE
-- ==============================================================================

-- 1. Composite Index for Shop Isolation & Chronological Range Pagination
CREATE INDEX IF NOT EXISTS idx_purchases_shop_created 
    ON public.purchases(shop_id, created_at DESC);

-- 2. Index for Fast Purchase Number Search
CREATE INDEX IF NOT EXISTS idx_purchases_shop_number 
    ON public.purchases(shop_id, invoice_number);

-- 3. Composite Index for Status Filtering & Pagination (DRAFT, COMPLETED)
CREATE INDEX IF NOT EXISTS idx_purchases_shop_status 
    ON public.purchases(shop_id, status, created_at DESC);

-- 4. Composite Index for Supplier Filtering & Chronological Ordering
CREATE INDEX IF NOT EXISTS idx_purchases_shop_supplier_date 
    ON public.purchases(shop_id, supplier_id, created_at DESC);
