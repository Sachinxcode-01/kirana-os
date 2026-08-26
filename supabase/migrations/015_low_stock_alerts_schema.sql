-- ==============================================================================
-- KIRANAOS MIGRATION 015: LOW-STOCK ALERTS DEDUPLICATION & REALTIME TRIGGER
-- ==============================================================================

-- 1. Create low_stock_alerts Table with Shop & Product Unique Constraint
CREATE TABLE IF NOT EXISTS public.low_stock_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES public.shops(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    current_quantity NUMERIC(12, 3) NOT NULL,
    minimum_quantity NUMERIC(12, 3) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'low_stock', -- 'low_stock', 'out_of_stock'
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_shop_product_alert UNIQUE(shop_id, product_id)
);

-- 2. Indexes for Fast Alert Queries & Filtering
CREATE INDEX IF NOT EXISTS idx_low_stock_alerts_shop ON public.low_stock_alerts(shop_id, is_read, status);
CREATE INDEX IF NOT EXISTS idx_low_stock_alerts_product ON public.low_stock_alerts(product_id);

-- 3. Row Level Security Policy
ALTER TABLE public.low_stock_alerts ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'low_stock_alerts' AND policyname = 'rls_low_stock_alerts_all'
    ) THEN
        CREATE POLICY rls_low_stock_alerts_all ON public.low_stock_alerts
            FOR ALL
            USING (shop_id IN (SELECT get_user_shop_ids()))
            WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));
    END IF;
END $$;

-- 4. Automatic Trigger Function for Low-Stock Alert Upsert / Resolution
CREATE OR REPLACE FUNCTION public.trg_product_stock_alert()
RETURNS TRIGGER AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    -- Check if product is active and current stock is <= min_stock_alert
    IF NEW.is_active = TRUE AND NEW.current_stock <= NEW.min_stock_alert THEN
        IF NEW.current_stock <= 0 THEN
            v_status := 'out_of_stock';
        ELSE
            v_status := 'low_stock';
        END IF;

        -- Upsert into low_stock_alerts with deduplication
        INSERT INTO public.low_stock_alerts (
            shop_id,
            product_id,
            current_quantity,
            minimum_quantity,
            status,
            is_read,
            updated_at
        ) VALUES (
            NEW.shop_id,
            NEW.id,
            NEW.current_stock,
            NEW.min_stock_alert,
            v_status,
            FALSE,
            NOW()
        )
        ON CONFLICT (shop_id, product_id) DO UPDATE SET
            current_quantity = EXCLUDED.current_quantity,
            minimum_quantity = EXCLUDED.minimum_quantity,
            status = EXCLUDED.status,
            updated_at = NOW();
    ELSE
        -- Stock has been replenished above minimum_stock_alert: Resolve/Delete alert
        DELETE FROM public.low_stock_alerts
        WHERE shop_id = NEW.shop_id AND product_id = NEW.id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Attach Trigger to Products Table
DROP TRIGGER IF EXISTS trg_product_stock_alert_event ON public.products;
CREATE TRIGGER trg_product_stock_alert_event
    AFTER INSERT OR UPDATE OF current_stock, min_stock_alert, is_active
    ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION public.trg_product_stock_alert();

-- 6. Enable Realtime Publication for Low Stock Alerts
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'low_stock_alerts'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.low_stock_alerts;
    END IF;
END $$;
