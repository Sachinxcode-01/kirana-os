-- ==============================================================================
-- KIRANAOS MIGRATION 022: CUSTOMER FOUNDATION SCHEMA
-- ==============================================================================

ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS email VARCHAR(255);
ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE public.customers ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_customers_shop_phone ON public.customers(shop_id, phone);
CREATE INDEX IF NOT EXISTS idx_customers_shop_name ON public.customers(shop_id, name);
CREATE INDEX IF NOT EXISTS idx_customers_shop_archived ON public.customers(shop_id, is_archived);
