-- ==============================================================================
-- KiranaOS — Development Seed Data
-- CAUTION: FOR LOCAL AND DEVELOPMENT STAGING TESTING ONLY
-- DO NOT RUN IN PRODUCTION ENVIRONMENTS
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. SYSTEM ROLES & PERMISSIONS CATALOG
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

-- Map permissions to roles
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

    -- Owner receives all permissions
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT v_owner_id, id FROM permissions
    ON CONFLICT DO NOTHING;

    -- Manager permissions
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

    -- Cashier permissions
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT v_cashier_id, id FROM permissions 
    WHERE code IN (
        'product.read',
        'billing.create',
        'customer.read', 'customer.create',
        'credit.read', 'credit.create', 'credit.payment'
    )
    ON CONFLICT DO NOTHING;

    -- Inventory staff permissions
    INSERT INTO role_permissions (role_id, permission_id)
    SELECT v_inv_id, id FROM permissions 
    WHERE code IN ('product.read', 'inventory.read', 'inventory.adjust')
    ON CONFLICT DO NOTHING;
END $$;
