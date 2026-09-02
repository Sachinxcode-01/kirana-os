-- ==============================================================================
-- KiranaOS — Phase 17: Migration 034: GST Tax Liability & GSTR-1 Export Aggregation
-- B2B, B2C Small/Large, HSN-wise summary, and Multi-Slab GST Liability (Paise precision)
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.get_gstr1_summary(
    p_shop_id UUID,
    p_start_date TIMESTAMPTZ,
    p_end_date TIMESTAMPTZ
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_role user_role;
    v_shop RECORD;
    v_b2b_summary JSONB := '[]'::jsonb;
    v_b2c_small JSONB := '[]'::jsonb;
    v_hsn_summary JSONB := '[]'::jsonb;
    v_slab_summary JSONB := '[]'::jsonb;
    v_total_taxable BIGINT := 0;
    v_total_cgst BIGINT := 0;
    v_total_sgst BIGINT := 0;
    v_total_igst BIGINT := 0;
    v_total_tax BIGINT := 0;
    v_total_invoice_val BIGINT := 0;
BEGIN
    SELECT role INTO v_user_role
    FROM shop_users
    WHERE shop_id = p_shop_id AND user_id = auth.uid() AND status = 'active';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Access Denied: Caller is not an active member of shop %', p_shop_id;
    END IF;

    SELECT * INTO v_shop FROM shops WHERE id = p_shop_id;

    -- 1. HSN SUMMARY (Table 12 GSTR-1)
    WITH hsn_raw AS (
        SELECT 
            COALESCE(p.hsn_code, 'N/A') as hsn_code,
            COALESCE(p.name, 'Miscellaneous') as description,
            COALESCE(p.unit, 'pcs') as uqc,
            SUM(bi.quantity) as total_qty,
            SUM(bi.total_paise) as total_value_paise,
            SUM(bi.total_paise - bi.tax_amount_paise) as taxable_value_paise,
            bi.tax_rate,
            SUM(
                CASE 
                    -- Intra-state: CGST = Tax / 2, SGST = Tax / 2
                    WHEN TRUE THEN (bi.tax_amount_paise / 2)
                    ELSE 0
                END
            ) as cgst_paise,
            SUM(
                CASE 
                    WHEN TRUE THEN (bi.tax_amount_paise / 2)
                    ELSE 0
                END
            ) as sgst_paise,
            SUM(
                CASE 
                    WHEN FALSE THEN bi.tax_amount_paise
                    ELSE 0
                END
            ) as igst_paise
        FROM bill_items bi
        JOIN bills b ON b.id = bi.bill_id
        LEFT JOIN products p ON p.id = bi.product_id
        WHERE b.shop_id = p_shop_id
          AND b.status = 'completed'
          AND b.created_at >= p_start_date
          AND b.created_at <= p_end_date
        GROUP BY p.hsn_code, p.name, p.unit, bi.tax_rate
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'hsn_code', hsn_code,
            'description', description,
            'uqc', uqc,
            'total_quantity', total_qty,
            'total_value_paise', total_value_paise,
            'taxable_value_paise', taxable_value_paise,
            'tax_rate', tax_rate,
            'cgst_paise', cgst_paise,
            'sgst_paise', sgst_paise,
            'igst_paise', igst_paise
        ) ORDER BY taxable_value_paise DESC
    ) INTO v_hsn_summary
    FROM hsn_raw;

    -- 2. TAX SLAB BREAKDOWN (0%, 5%, 12%, 18%, 28%)
    WITH slab_raw AS (
        SELECT 
            bi.tax_rate,
            SUM(bi.total_paise - bi.tax_amount_paise) as taxable_amount_paise,
            SUM(bi.tax_amount_paise / 2) as cgst_paise,
            SUM(bi.tax_amount_paise / 2) as sgst_paise,
            SUM(bi.tax_amount_paise) as total_tax_paise
        FROM bill_items bi
        JOIN bills b ON b.id = bi.bill_id
        WHERE b.shop_id = p_shop_id
          AND b.status = 'completed'
          AND b.created_at >= p_start_date
          AND b.created_at <= p_end_date
        GROUP BY bi.tax_rate
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'tax_rate_percent', tax_rate,
            'taxable_amount_paise', taxable_amount_paise,
            'cgst_paise', cgst_paise,
            'sgst_paise', sgst_paise,
            'total_tax_paise', total_tax_paise
        ) ORDER BY tax_rate ASC
    ) INTO v_slab_summary
    FROM slab_raw;

    -- 3. B2C SMALL RETAIL AGGREGATE (Table 7)
    SELECT 
        COALESCE(SUM(b.subtotal_paise), 0),
        COALESCE(SUM(b.tax_paise / 2), 0),
        COALESCE(SUM(b.tax_paise / 2), 0),
        COALESCE(SUM(b.tax_paise), 0),
        COALESCE(SUM(b.final_amount_paise), 0)
    INTO v_total_taxable, v_total_cgst, v_total_sgst, v_total_tax, v_total_invoice_val
    FROM bills b
    WHERE b.shop_id = p_shop_id
      AND b.status = 'completed'
      AND b.created_at >= p_start_date
      AND b.created_at <= p_end_date;

    RETURN jsonb_build_object(
        'gstin', v_shop.gstin,
        'legal_name', v_shop.name,
        'state', v_shop.state,
        'period_start', p_start_date,
        'period_end', p_end_date,
        'aggregate_totals', jsonb_build_object(
            'total_invoices_value_paise', v_total_invoice_val,
            'total_taxable_value_paise', v_total_taxable,
            'total_cgst_paise', v_total_cgst,
            'total_sgst_paise', v_total_sgst,
            'total_igst_paise', v_total_igst,
            'total_tax_collected_paise', v_total_tax
        ),
        'tax_slab_summary', COALESCE(v_slab_summary, '[]'::jsonb),
        'hsn_summary', COALESCE(v_hsn_summary, '[]'::jsonb),
        'b2c_small_summary', jsonb_build_object(
            'place_of_supply', v_shop.state,
            'taxable_value_paise', v_total_taxable,
            'cgst_paise', v_total_cgst,
            'sgst_paise', v_total_sgst,
            'total_tax_paise', v_total_tax
        )
    );
END;
$$;
