-- ==============================================================================
-- KiranaOS — Phase 02: Migration 002: Indexes & Integrity Constraints
-- High-Performance Composite Indexes, GIN Trigram Search, Financial CHECK Constraints
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. FINANCIAL & LOGICAL CHECK CONSTRAINTS
-- ------------------------------------------------------------------------------
ALTER TABLE products
    ADD CONSTRAINT chk_products_positive_mrp CHECK (mrp_paise >= 0),
    ADD CONSTRAINT chk_products_positive_sp CHECK (selling_price_paise >= 0),
    ADD CONSTRAINT chk_products_positive_purchase CHECK (purchase_price_paise >= 0),
    ADD CONSTRAINT chk_products_tax_rate CHECK (tax_rate_percentage >= 0.00 AND tax_rate_percentage <= 100.00),
    ADD CONSTRAINT chk_products_stock_alert CHECK (min_stock_alert >= 0.000);

ALTER TABLE bills
    ADD CONSTRAINT chk_bills_subtotal CHECK (subtotal_paise >= 0),
    ADD CONSTRAINT chk_bills_discount CHECK (discount_paise >= 0),
    ADD CONSTRAINT chk_bills_total CHECK (total_paise >= 0);

ALTER TABLE bill_items
    ADD CONSTRAINT chk_bill_items_quantity CHECK (quantity > 0),
    ADD CONSTRAINT chk_bill_items_price CHECK (unit_price_paise >= 0),
    ADD CONSTRAINT chk_bill_items_total CHECK (total_paise >= 0);

ALTER TABLE customers
    ADD CONSTRAINT chk_customers_credit_limit CHECK (credit_limit_paise >= 0),
    ADD CONSTRAINT chk_customers_debt CHECK (current_debt_paise >= 0);

ALTER TABLE credit_transactions
    ADD CONSTRAINT chk_credit_amount CHECK (amount_paise > 0);

ALTER TABLE payments
    ADD CONSTRAINT chk_payments_amount CHECK (amount_paise > 0);

ALTER TABLE purchases
    ADD CONSTRAINT chk_purchases_total CHECK (total_paise >= 0);

ALTER TABLE expenses
    ADD CONSTRAINT chk_expenses_amount CHECK (amount_paise > 0);

-- ------------------------------------------------------------------------------
-- 2. HIGH-PERFORMANCE SEARCH & COMPOSITE INDEXES
-- ------------------------------------------------------------------------------

-- Shops & Auth Memberships
CREATE INDEX IF NOT EXISTS idx_shops_owner ON shops(owner_id);
CREATE INDEX IF NOT EXISTS idx_shop_users_lookup ON shop_users(shop_id, user_id);
CREATE INDEX IF NOT EXISTS idx_shop_users_user ON shop_users(user_id);

-- Products & Barcodes (Sub-15ms Index Lookup)
CREATE INDEX IF NOT EXISTS idx_products_shop_active ON products(shop_id, is_active);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(shop_id, category_id);
CREATE INDEX IF NOT EXISTS idx_products_name_trgm ON products USING gin(name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_product_barcodes_lookup ON product_barcodes(shop_id, barcode);
CREATE INDEX IF NOT EXISTS idx_product_barcodes_product ON product_barcodes(product_id);
CREATE INDEX IF NOT EXISTS idx_product_images_product ON product_images(product_id);

-- Inventory & Stock Audit
CREATE INDEX IF NOT EXISTS idx_inventory_movements_audit ON inventory_movements(shop_id, product_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_stock_batches_expiry ON stock_batches(shop_id, expiry_date);

-- Customers & Credit Ledger
CREATE INDEX IF NOT EXISTS idx_customers_shop_phone ON customers(shop_id, phone);
CREATE INDEX IF NOT EXISTS idx_customers_shop_name_trgm ON customers USING gin(name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_credit_customer_history ON credit_transactions(customer_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_credit_shop_date ON credit_transactions(shop_id, created_at DESC);

-- Billing & Invoices
CREATE INDEX IF NOT EXISTS idx_bills_shop_created ON bills(shop_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bills_customer ON bills(customer_id);
CREATE INDEX IF NOT EXISTS idx_bills_bill_number ON bills(shop_id, bill_number);
CREATE INDEX IF NOT EXISTS idx_bill_items_bill ON bill_items(bill_id);
CREATE INDEX IF NOT EXISTS idx_payments_bill ON payments(bill_id);

-- Suppliers & Procurement
CREATE INDEX IF NOT EXISTS idx_suppliers_shop_phone ON suppliers(shop_id, phone);
CREATE INDEX IF NOT EXISTS idx_purchases_supplier ON purchases(shop_id, supplier_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase ON purchase_items(purchase_id);

-- Expenses & Audit Logs
CREATE INDEX IF NOT EXISTS idx_expenses_shop_created ON expenses(shop_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_shop_actor ON audit_logs(shop_id, actor_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_id, is_read, created_at DESC);

-- Sync Ingestion & Idempotency Audit
CREATE INDEX IF NOT EXISTS idx_sync_shop_audit ON sync_operations(shop_id, server_timestamp DESC);
