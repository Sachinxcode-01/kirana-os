-- ==============================================================================
-- KiranaOS — Phase 13.8: Migration 027: Sales Dashboard Server-Side Aggregation RPC
-- Fast, shop-timezone-aware server-side aggregations for Today's Sales, Bill Count,
-- Top Products, and Recent Sales Trend
-- ==============================================================================

CREATE INDEX IF NOT EXISTS idx_bills_dashboard_aggregation 
    ON public.bills(shop_id, is_cancelled, payment_status, created_at);

CREATE OR REPLACE FUNCTION public.get_sales_dashboard_metrics(
    p_shop_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role user_role;
    v_timezone TEXT := 'Asia/Kolkata';
    v_today_start TIMESTAMPTZ;
    v_today_end TIMESTAMPTZ;
    v_yesterday_start TIMESTAMPTZ;
    
    v_today_sales_paise BIGINT := 0;
    v_today_bills_count INT := 0;
    v_yesterday_bills_count INT := 0;
    v_total_udhaar_paise BIGINT := 0;
    v_low_stock_count INT := 0;
    
    v_top_products JSONB := '[]'::jsonb;
    v_sales_trend JSONB := '[]'::jsonb;
    v_recent_bills JSONB := '[]'::jsonb;
BEGIN
    -- 1. Security Check: Caller must belong to the active shop if authenticated
    IF auth.uid() IS NOT NULL THEN
        SELECT role INTO v_user_role
        FROM shop_users
        WHERE shop_id = p_shop_id AND user_id = auth.uid() AND status = 'active';

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Access Denied: Caller is not an active member of shop %', p_shop_id;
        END IF;
    END IF;

    -- 2. Fetch Shop Timezone
    SELECT COALESCE(timezone, 'Asia/Kolkata') INTO v_timezone
    FROM shops
    WHERE id = p_shop_id;

    -- 3. Calculate Date Boundaries in Shop Timezone
    v_today_start := DATE_TRUNC('day', NOW() AT TIME ZONE v_timezone) AT TIME ZONE v_timezone;
    v_today_end := v_today_start + INTERVAL '1 day';
    v_yesterday_start := v_today_start - INTERVAL '1 day';

    -- 4. Today's Sales Summary & Bill Count (Completed, non-cancelled)
    SELECT 
        COALESCE(SUM(total_paise), 0),
        COUNT(id)
    INTO 
        v_today_sales_paise,
        v_today_bills_count
    FROM bills
    WHERE shop_id = p_shop_id
      AND payment_status IN ('paid', 'completed')
      AND is_cancelled = false
      AND created_at >= v_today_start
      AND created_at < v_today_end;

    -- 5. Yesterday's Bill Count (Completed, non-cancelled)
    SELECT COUNT(id)
    INTO v_yesterday_bills_count
    FROM bills
    WHERE shop_id = p_shop_id
      AND payment_status IN ('paid', 'completed')
      AND is_cancelled = false
      AND created_at >= v_yesterday_start
      AND created_at < v_today_start;

    -- 6. Today's Top Products (Rank by total quantity sold from completed bill_items today)
    SELECT COALESCE(jsonb_agg(tp), '[]'::jsonb) INTO v_top_products FROM (
        SELECT 
            bi.product_name,
            SUM(bi.quantity)::NUMERIC(12, 3) as quantity_sold
        FROM bill_items bi
        JOIN bills b ON bi.bill_id = b.id
        WHERE b.shop_id = p_shop_id
          AND b.payment_status IN ('paid', 'completed')
          AND b.is_cancelled = false
          AND b.created_at >= v_today_start
          AND b.created_at < v_today_end
        GROUP BY bi.product_name
        ORDER BY quantity_sold DESC
        LIMIT 5
    ) tp;

    -- 7. Basic Sales Trend (Past 7 days including today)
    SELECT COALESCE(jsonb_agg(st), '[]'::jsonb) INTO v_sales_trend FROM (
        SELECT 
            TO_CHAR(d.day_date, 'YYYY-MM-DD') as date_str,
            TO_CHAR(d.day_date, 'Dy') as day_label,
            COALESCE(SUM(b.total_paise), 0)::BIGINT as total_paise
        FROM (
            SELECT ( (v_today_start AT TIME ZONE v_timezone)::date - (i || ' days')::INTERVAL )::date as day_date
            FROM generate_series(6, 0, -1) i
        ) d
        LEFT JOIN bills b ON b.shop_id = p_shop_id
          AND b.payment_status IN ('paid', 'completed')
          AND b.is_cancelled = false
          AND b.created_at >= (v_today_start - INTERVAL '6 days')
          AND b.created_at < v_today_end
          AND (b.created_at AT TIME ZONE v_timezone)::date = d.day_date
        GROUP BY d.day_date
        ORDER BY d.day_date ASC
    ) st;

    -- 8. Additional contextual dashboard stats (Udhaar & Low stock count)
    SELECT COALESCE(SUM(current_debt_paise), 0)
    INTO v_total_udhaar_paise
    FROM customers
    WHERE shop_id = p_shop_id;

    SELECT COUNT(id)
    INTO v_low_stock_count
    FROM products
    WHERE shop_id = p_shop_id AND is_active = true AND current_stock <= min_stock_alert;

    -- 9. Recent completed bills (top 5)
    SELECT COALESCE(jsonb_agg(rb), '[]'::jsonb) INTO v_recent_bills FROM (
        SELECT 
            id,
            bill_number as "billNumber",
            total_paise as "totalPaise",
            payment_status as "paymentStatus",
            created_at as "createdAt"
        FROM bills
        WHERE shop_id = p_shop_id AND payment_status IN ('paid', 'completed') AND is_cancelled = false
        ORDER BY created_at DESC
        LIMIT 5
    ) rb;

    RETURN jsonb_build_object(
        'todaySalesPaise', v_today_sales_paise,
        'todayBillsCount', v_today_bills_count,
        'yesterdayBillsCount', v_yesterday_bills_count,
        'topProducts', v_top_products,
        'salesTrend', v_sales_trend,
        'totalUdhaarOutstandingPaise', v_total_udhaar_paise,
        'lowStockItemsCount', v_low_stock_count,
        'recentBills', v_recent_bills,
        'serverTimestamp', NOW()
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_sales_dashboard_metrics TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_sales_dashboard_metrics TO service_role;
