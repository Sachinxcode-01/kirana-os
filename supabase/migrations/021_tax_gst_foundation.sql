-- ==============================================================================
-- KIRANAOS MIGRATION 021: TAX / GST FOUNDATION SCHEMA
-- ==============================================================================

ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS is_tax_enabled BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS default_tax_rate NUMERIC(5, 2) NOT NULL DEFAULT 0.00;

ALTER TABLE public.products ADD COLUMN IF NOT EXISTS tax_type VARCHAR(20) NOT NULL DEFAULT 'shop_default';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'chk_shops_default_tax_rate'
    ) THEN
        ALTER TABLE public.shops ADD CONSTRAINT chk_shops_default_tax_rate 
        CHECK (default_tax_rate IN (0.00, 5.00, 12.00, 18.00, 28.00));
    END IF;
END $$;
