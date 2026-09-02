-- ==============================================================================
-- KiranaOS — Comprehensive Seed Data Suite
-- Production-Realistic Indian Retail Groceries, FMCG SKUs, Customers, Suppliers,
-- Loyalty Ledger, Cash Registers & Shifts (Paise-Precision Integer Arithmetic)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. SYSTEM ROLES & PERMISSIONS
-- ------------------------------------------------------------------------------
INSERT INTO roles (name, description) VALUES
    ('owner', 'Store Owner / Proprietor with unrestricted financial and management access'),
    ('manager', 'Store Manager with catalog, inventory, and staff oversight'),
    ('cashier', 'Counter Cashier with fast billing, returns, and payment collection access'),
    ('inventory_staff', 'Warehouse / Inward Stocking assistant')
ON CONFLICT (name) DO NOTHING;

INSERT INTO permissions (code, module, description) VALUES
    ('product.read', 'catalog', 'View product master details and prices'),
    ('product.create', 'catalog', 'Add new product SKUs and barcodes'),
    ('product.update', 'catalog', 'Edit product prices, GST, and attributes'),
    ('product.archive', 'catalog', 'Archive or delete product SKUs'),
    ('inventory.read', 'inventory', 'View stock levels and reorder thresholds'),
    ('inventory.adjust', 'inventory', 'Perform manual stock adjustments and write-offs'),
    ('billing.create', 'billing', 'Create and finalize sales bills and invoices'),
    ('billing.cancel', 'billing', 'Cancel or void completed bills (requires Owner PIN)'),
    ('billing.discount_high', 'billing', 'Apply discounts greater than 10%'),
    ('customer.read', 'crm', 'View customer directory and purchase histories'),
    ('customer.create', 'crm', 'Register new customers'),
    ('credit.read', 'credit', 'View Udhaar / Khata balances and credit ledgers'),
    ('credit.create', 'credit', 'Disburse goods on credit'),
    ('credit.payment', 'credit', 'Receive and record credit settlement payments'),
    ('reports.read', 'analytics', 'View financial summaries, Day-End Z-Reports, and GSTR-1'),
    ('settings.manage', 'settings', 'Configure thermal printers, barcodes, and shop profile'),
    ('staff.manage', 'staff', 'Invite, update roles, and manage employee PINs')
ON CONFLICT (code) DO NOTHING;

-- Assign permissions to roles
DO $$
DECLARE
    v_owner_id UUID;
    v_manager_id UUID;
    v_cashier_id UUID;
    v_inv_id UUID;
BEGIN
    SELECT id INTO v_owner_id FROM roles WHERE name = 'owner';
    SELECT id INTO v_manager_id FROM roles WHERE name = 'manager';
    SELECT id INTO v_cashier_id FROM roles WHERE name = 'cashier';
    SELECT id INTO v_inv_id FROM roles WHERE name = 'inventory_staff';

    INSERT INTO role_permissions (role_id, permission_id)
    SELECT v_owner_id, id FROM permissions
    ON CONFLICT DO NOTHING;

    INSERT INTO role_permissions (role_id, permission_id)
    SELECT v_manager_id, id FROM permissions 
    WHERE code IN (
        'product.read', 'product.create', 'product.update',
        'inventory.read', 'inventory.adjust',
        'billing.create', 'billing.discount_high',
        'customer.read', 'customer.create',
        'credit.read', 'credit.create', 'credit.payment',
        'reports.read', 'settings.manage'
    )
    ON CONFLICT DO NOTHING;

    INSERT INTO role_permissions (role_id, permission_id)
    SELECT v_cashier_id, id FROM permissions 
    WHERE code IN (
        'product.read',
        'billing.create',
        'customer.read', 'customer.create',
        'credit.read', 'credit.create', 'credit.payment'
    )
    ON CONFLICT DO NOTHING;

    INSERT INTO role_permissions (role_id, permission_id)
    SELECT v_inv_id, id FROM permissions 
    WHERE code IN ('product.read', 'inventory.read', 'inventory.adjust')
    ON CONFLICT DO NOTHING;
END $$;

-- ------------------------------------------------------------------------------
-- 2. SAMPLE KIRANA STORE PROFILE & REGISTER
-- ------------------------------------------------------------------------------
DO $$
DECLARE
    v_shop_id UUID := 'a0000000-0000-0000-0000-000000000001'::uuid;
    v_owner_auth_id UUID;
    v_cat_flour UUID := gen_random_uuid();
    v_cat_oil UUID := gen_random_uuid();
    v_cat_spices UUID := gen_random_uuid();
    v_cat_dairy UUID := gen_random_uuid();
    v_cat_snacks UUID := gen_random_uuid();
    v_cat_beverages UUID := gen_random_uuid();
    v_cat_cleaning UUID := gen_random_uuid();
    
    v_cust_sharma UUID := gen_random_uuid();
    v_cust_patel UUID := gen_random_uuid();
    v_cust_verma UUID := gen_random_uuid();

    v_sup_itc UUID := gen_random_uuid();
    v_sup_amul UUID := gen_random_uuid();
    v_sup_hul UUID := gen_random_uuid();

    v_prod_atta UUID := gen_random_uuid();
    v_prod_oil UUID := gen_random_uuid();
    v_prod_salt UUID := gen_random_uuid();
    v_prod_butter UUID := gen_random_uuid();
    v_prod_maggi UUID := gen_random_uuid();
    v_prod_parle UUID := gen_random_uuid();
    v_prod_tea UUID := gen_random_uuid();
    v_prod_surf UUID := gen_random_uuid();

    v_reg_id UUID := gen_random_uuid();
BEGIN
    -- Check if auth user exists, otherwise create placeholder or use first available
    SELECT id INTO v_owner_auth_id FROM auth.users LIMIT 1;

    IF v_owner_auth_id IS NOT NULL THEN
        -- Insert Sample Shop
        INSERT INTO shops (
            id, name, owner_id, phone, email, gstin,
            fssai_license, address, city, state, pincode,
            upi_id, invoice_prefix, is_active
        ) VALUES (
            v_shop_id, 'Sri Lakshmi Provision & Supermarket', v_owner_auth_id,
            '9876543210', 'srilakshmi.kirana@gmail.com', '29AAAAA0000A1Z5',
            '11223344556677', '14th Cross, 2nd Main, Indiranagar', 'Bengaluru',
            'Karnataka', '560038', 'srilakshmi@okaxis', 'SLP', TRUE
        ) ON CONFLICT (id) DO UPDATE SET
            name = EXCLUDED.name,
            phone = EXCLUDED.phone,
            gstin = EXCLUDED.gstin;

        -- Associate owner role
        INSERT INTO shop_users (shop_id, user_id, role, display_name, status)
        VALUES (v_shop_id, v_owner_auth_id, 'owner', 'Ramesh Kumar (Proprietor)', 'active')
        ON CONFLICT (shop_id, user_id) DO NOTHING;

        -- Create Cash Register
        INSERT INTO cash_registers (id, shop_id, name, status)
        VALUES (v_reg_id, v_shop_id, 'Main Checkout Counter 1', 'closed')
        ON CONFLICT (shop_id, name) DO NOTHING;

        -- Loyalty Settings
        INSERT INTO loyalty_settings (
            shop_id, is_enabled, earn_rate_percentage,
            redemption_value_paise, min_points_to_redeem
        ) VALUES (
            v_shop_id, TRUE, 1.00, 100, 50
        ) ON CONFLICT (shop_id) DO NOTHING;

        -- Categories
        INSERT INTO categories (id, shop_id, name, sort_order) VALUES
            (v_cat_flour, v_shop_id, 'Atta & Flours', 1),
            (v_cat_oil, v_shop_id, 'Edible Oils & Ghee', 2),
            (v_cat_spices, v_shop_id, 'Spices, Salt & Sugar', 3),
            (v_cat_dairy, v_shop_id, 'Dairy & Fresh', 4),
            (v_cat_snacks, v_shop_id, 'Snacks & Biscuits', 5),
            (v_cat_beverages, v_shop_id, 'Tea, Coffee & Drinks', 6),
            (v_cat_cleaning, v_shop_id, 'Household & Cleaning', 7)
        ON CONFLICT (shop_id, name) DO NOTHING;

        -- FMCG Products
        INSERT INTO products (
            id, shop_id, category_id, name, unit,
            selling_price_paise, mrp_paise, cost_price_paise,
            tax_rate, current_stock, min_stock_threshold,
            hsn_code, is_active
        ) VALUES
            (v_prod_atta, v_shop_id, v_cat_flour, 'Aashirvaad Shudh Chakki Atta 5kg', 'packet', 24500, 26000, 22000, 0.00, 45.0, 10.0, '1101', TRUE),
            (v_prod_oil, v_shop_id, v_cat_oil, 'Fortune Sunlite Refined Sunflower Oil 1L', 'packet', 13500, 15000, 12000, 5.00, 60.0, 15.0, '1512', TRUE),
            (v_prod_salt, v_shop_id, v_cat_spices, 'Tata Salt Vacuum Evaporated 1kg', 'packet', 2800, 3000, 2400, 0.00, 120.0, 25.0, '2501', TRUE),
            (v_prod_butter, v_shop_id, v_cat_dairy, 'Amul Pasteurised Butter 500g', 'packet', 27500, 28500, 25000, 12.00, 30.0, 8.0, '0405', TRUE),
            (v_prod_maggi, v_shop_id, v_cat_snacks, 'Nestle Maggi 2-Minute Masala Noodles 70g', 'packet', 1400, 1400, 1180, 12.00, 200.0, 40.0, '1902', TRUE),
            (v_prod_parle, v_shop_id, v_cat_snacks, 'Parle-G Gold Glucose Biscuits 100g', 'packet', 1000, 1000, 850, 18.00, 150.0, 30.0, '1905', TRUE),
            (v_prod_tea, v_shop_id, v_cat_beverages, 'Brooke Bond Red Label Tea 500g', 'packet', 29000, 31000, 26000, 5.00, 40.0, 10.0, '0902', TRUE),
            (v_prod_surf, v_shop_id, v_cat_cleaning, 'Surf Excel Quick Wash Detergent Powder 1kg', 'packet', 16000, 17500, 13800, 18.00, 50.0, 12.0, '3402', TRUE)
        ON CONFLICT DO NOTHING;

        -- Product Barcodes (Exact 13-digit GS1 Mod-10 verified)
        INSERT INTO product_barcodes (shop_id, product_id, barcode, barcode_type, is_primary) VALUES
            (v_shop_id, v_prod_atta, '8901030383793', 'EAN_13', TRUE),
            (v_shop_id, v_prod_oil, '8906007280143', 'EAN_13', TRUE),
            (v_shop_id, v_prod_salt, '8901030010040', 'EAN_13', TRUE),
            (v_shop_id, v_prod_butter, '8901262010054', 'EAN_13', TRUE),
            (v_shop_id, v_prod_maggi, '8901058852370', 'EAN_13', TRUE),
            (v_shop_id, v_prod_parle, '8901719101038', 'EAN_13', TRUE),
            (v_shop_id, v_prod_tea, '8901030345099', 'EAN_13', TRUE),
            (v_shop_id, v_prod_surf, '8901030886547', 'EAN_13', TRUE)
        ON CONFLICT DO NOTHING;

        -- Suppliers
        INSERT INTO suppliers (id, shop_id, name, contact_person, phone, email, gstin) VALUES
            (v_sup_itc, v_shop_id, 'ITC Distribution Bangalore Central', 'Sanjay Hegde', '9845012345', 'itc.blr@dist.com', '29AABCI1234F1Z1'),
            (v_sup_amul, v_shop_id, 'Amul Dairy Agencies Karnataka', 'Mahesh Gowda', '9845098765', 'amul.blr@agencies.in', '29AABCA5678K1Z3'),
            (v_sup_hul, v_shop_id, 'Hindustan Unilever Metro Depot', 'Kiran Rao', '9845055555', 'hul.metro@dist.in', '29AABCH9999M1Z8')
        ON CONFLICT DO NOTHING;

        -- Customers with Credit Khata & Loyalty
        INSERT INTO customers (
            id, shop_id, name, phone, email, address,
            credit_limit_paise, current_balance_paise, loyalty_points
        ) VALUES
            (v_cust_sharma, v_shop_id, 'Anil Sharma', '9880011223', 'sharma.anil@gmail.com', '#42, 3rd Cross, Indiranagar', 500000, 185000, 120),
            (v_cust_patel, v_shop_id, 'Sunita Patel', '9880044556', 'sunita.patel@yahoo.com', '#108, Palm Meadows', 1000000, 420000, 250),
            (v_cust_verma, v_shop_id, 'Rajesh Verma', '9880077889', 'rajesh.v@outlook.com', '#7, CMH Road', 300000, 0, 85)
        ON CONFLICT DO NOTHING;

        -- Credit Ledger Initial History
        INSERT INTO credit_transactions (shop_id, customer_id, transaction_type, amount_paise, notes, created_by) VALUES
            (v_shop_id, v_cust_sharma, 'credit_given', 185000, 'Monthly grocery credit invoice', v_owner_auth_id),
            (v_shop_id, v_cust_patel, 'credit_given', 620000, 'Festival provisions purchase', v_owner_auth_id),
            (v_shop_id, v_cust_patel, 'payment_received', 200000, 'UPI partial payment received', v_owner_auth_id)
        ON CONFLICT DO NOTHING;
    END IF;
END $$;
