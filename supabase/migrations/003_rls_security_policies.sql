-- ==============================================================================
-- KiranaOS — Phase 02: Migration 003: Row-Level Security (RLS) Policies
-- Zero-Trust Multi-Tenant Isolation with Granular RBAC Role Enforcement
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. ENABLE RLS ACROSS ALL TABLES
-- ------------------------------------------------------------------------------
ALTER TABLE shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE shop_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE units ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_barcodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplier_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE bill_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE bill_returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE bill_return_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_operations ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- 2. SECURITY DEFINER HELPER FUNCTIONS
-- ------------------------------------------------------------------------------

-- Returns the set of active shop IDs for the current authenticated caller
CREATE OR REPLACE FUNCTION get_user_shop_ids()
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT shop_id 
    FROM shop_users 
    WHERE user_id = auth.uid() 
      AND status = 'active';
$$;

-- Validates if the authenticated user holds specific roles in the given shop
CREATE OR REPLACE FUNCTION user_has_shop_role(p_shop_id UUID, p_roles user_role[])
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM shop_users 
        WHERE shop_id = p_shop_id 
          AND user_id = auth.uid() 
          AND role = ANY(p_roles)
          AND status = 'active'
    );
$$;

-- ------------------------------------------------------------------------------
-- 3. GLOBAL ROLE & PERMISSION CATALOG (Read-Only for Authenticated Users)
-- ------------------------------------------------------------------------------
CREATE POLICY rls_roles_select ON roles FOR SELECT TO authenticated USING (true);
CREATE POLICY rls_permissions_select ON permissions FOR SELECT TO authenticated USING (true);
CREATE POLICY rls_role_permissions_select ON role_permissions FOR SELECT TO authenticated USING (true);

-- ------------------------------------------------------------------------------
-- 4. SHOPS & MEMBERSHIPS RLS POLICIES
-- ------------------------------------------------------------------------------

-- Shops: Users can view shops they belong to or own
CREATE POLICY rls_shops_select ON shops
    FOR SELECT TO authenticated
    USING (id IN (SELECT get_user_shop_ids()) OR owner_id = auth.uid());

CREATE POLICY rls_shops_insert ON shops
    FOR INSERT TO authenticated
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY rls_shops_update ON shops
    FOR UPDATE TO authenticated
    USING (owner_id = auth.uid() OR user_has_shop_role(id, ARRAY['owner'::user_role]))
    WITH CHECK (owner_id = auth.uid() OR user_has_shop_role(id, ARRAY['owner'::user_role]));

-- Shop Users: Users can view staff in their shops; Owners/Managers manage staff
CREATE POLICY rls_shop_users_select ON shop_users
    FOR SELECT TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY rls_shop_users_insert ON shop_users
    FOR INSERT TO authenticated
    WITH CHECK (user_has_shop_role(shop_id, ARRAY['owner'::user_role, 'manager'::user_role]));

CREATE POLICY rls_shop_users_update ON shop_users
    FOR UPDATE TO authenticated
    USING (user_has_shop_role(shop_id, ARRAY['owner'::user_role, 'manager'::user_role]))
    WITH CHECK (user_has_shop_role(shop_id, ARRAY['owner'::user_role, 'manager'::user_role]));

CREATE POLICY rls_shop_users_delete ON shop_users
    FOR DELETE TO authenticated
    USING (user_has_shop_role(shop_id, ARRAY['owner'::user_role]));

-- ------------------------------------------------------------------------------
-- 5. MASTER CATALOG & INVENTORY RLS POLICIES
-- ------------------------------------------------------------------------------

-- Categories
CREATE POLICY rls_categories_all ON categories
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

-- Brands & Units
CREATE POLICY rls_brands_all ON brands
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY rls_units_all ON units
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

-- Products & Barcodes
CREATE POLICY rls_products_all ON products
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY rls_product_barcodes_all ON product_barcodes
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY rls_product_images_all ON product_images
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY rls_price_history_all ON price_history
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY rls_stock_batches_all ON stock_batches
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY rls_inventory_movements_all ON inventory_movements
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

-- ------------------------------------------------------------------------------
-- 6. CUSTOMERS & CREDIT LEDGER RLS POLICIES
-- ------------------------------------------------------------------------------
CREATE POLICY rls_customers_all ON customers
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY rls_credit_transactions_all ON credit_transactions
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

-- ------------------------------------------------------------------------------
-- 7. BILLING, PAYMENTS & RETURNS RLS POLICIES
-- ------------------------------------------------------------------------------
CREATE POLICY rls_bills_all ON bills
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

-- Bill Items: Accessible if the parent bill belongs to user's shop
CREATE POLICY rls_bill_items_all ON bill_items
    FOR ALL TO authenticated
    USING (bill_id IN (SELECT id FROM bills WHERE shop_id IN (SELECT get_user_shop_ids())))
    WITH CHECK (bill_id IN (SELECT id FROM bills WHERE shop_id IN (SELECT get_user_shop_ids())));

CREATE POLICY rls_bill_returns_all ON bill_returns
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY rls_bill_return_items_all ON bill_return_items
    FOR ALL TO authenticated
    USING (return_id IN (SELECT id FROM bill_returns WHERE shop_id IN (SELECT get_user_shop_ids())))
    WITH CHECK (return_id IN (SELECT id FROM bill_returns WHERE shop_id IN (SELECT get_user_shop_ids())));

CREATE POLICY rls_payments_all ON payments
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

-- ------------------------------------------------------------------------------
-- 8. SUPPLIERS, PURCHASES & EXPENSES RLS POLICIES
-- ------------------------------------------------------------------------------
CREATE POLICY rls_suppliers_all ON suppliers
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY rls_purchases_all ON purchases
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY rls_purchase_items_all ON purchase_items
    FOR ALL TO authenticated
    USING (purchase_id IN (SELECT id FROM purchases WHERE shop_id IN (SELECT get_user_shop_ids())))
    WITH CHECK (purchase_id IN (SELECT id FROM purchases WHERE shop_id IN (SELECT get_user_shop_ids())));

CREATE POLICY rls_supplier_payments_all ON supplier_payments
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY rls_expense_categories_all ON expense_categories
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY rls_expenses_all ON expenses
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

-- ------------------------------------------------------------------------------
-- 9. NOTIFICATIONS, AUDIT & OFFLINE SYNC RLS POLICIES
-- ------------------------------------------------------------------------------
CREATE POLICY rls_notifications_all ON notifications
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY rls_audit_logs_all ON audit_logs
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));

CREATE POLICY rls_sync_operations_all ON sync_operations
    FOR ALL TO authenticated
    USING (shop_id IN (SELECT get_user_shop_ids()))
    WITH CHECK (shop_id IN (SELECT get_user_shop_ids()));
