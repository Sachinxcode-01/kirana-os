-- ==============================================================================
-- KIRANAOS MIGRATION 020: BUSINESS SETTINGS SCHEMA
-- Business Hours, Currency Settings, and Bill Number Prefix Columns
-- ==============================================================================

ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS currency_code VARCHAR DEFAULT 'INR';
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS currency_symbol VARCHAR DEFAULT '₹';
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS decimal_precision INT DEFAULT 2;
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS bill_prefix VARCHAR DEFAULT 'INV-';
ALTER TABLE public.shops ADD COLUMN IF NOT EXISTS business_hours JSONB DEFAULT '{
    "monday": {"is_open": true, "open_time": "09:00", "close_time": "21:00"},
    "tuesday": {"is_open": true, "open_time": "09:00", "close_time": "21:00"},
    "wednesday": {"is_open": true, "open_time": "09:00", "close_time": "21:00"},
    "thursday": {"is_open": true, "open_time": "09:00", "close_time": "21:00"},
    "friday": {"is_open": true, "open_time": "09:00", "close_time": "21:00"},
    "saturday": {"is_open": true, "open_time": "09:00", "close_time": "21:00"},
    "sunday": {"is_open": true, "open_time": "09:00", "close_time": "21:00"}
}'::jsonb;
