-- ==============================================================================
-- KiranaOS — Phase 13.3: Migration 025: Discount Foundation Schema Enhancements
-- PostgreSQL 16 / Supabase Schema Definition & Historical Bill Snapshot Safety
-- ==============================================================================

-- 1. ADD DISCOUNT TYPE AND DISCOUNT VALUE COLUMNS TO BILLS TABLE
ALTER TABLE public.bills
    ADD COLUMN IF NOT EXISTS discount_type VARCHAR(20) NOT NULL DEFAULT 'none',
    ADD COLUMN IF NOT EXISTS discount_value NUMERIC(12, 2) NOT NULL DEFAULT 0.00;

-- 2. INDEX FOR DISCOUNT ANALYTICS & REPORTING
CREATE INDEX IF NOT EXISTS idx_bills_shop_discount ON public.bills(shop_id, discount_type) 
WHERE discount_type <> 'none';
