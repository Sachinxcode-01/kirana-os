-- ==============================================================================
-- KIRANAOS MIGRATION 014: STOCK OVERVIEW COMPOSITE INDEXES & REALTIME
-- ==============================================================================

-- 1. Enable Supabase Realtime Publication for Products Table (if not already enabled)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'products'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.products;
    END IF;
END $$;

-- 2. Composite Index for Shop Isolation & Stock Level Filtering
CREATE INDEX IF NOT EXISTS idx_products_shop_stock 
    ON public.products(shop_id, is_active, current_stock);

-- 3. Composite Index for Min Stock Alert Comparison
CREATE INDEX IF NOT EXISTS idx_products_shop_min_stock 
    ON public.products(shop_id, min_stock_alert);
