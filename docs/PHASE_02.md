# Phase 02 Summary & Technical Blueprint — KiranaOS

**Phase**: 02 — Real Backend, Database, Authentication, Storage & Offline Data Foundation  
**Status**: Completed & Verified  
**Document Version**: 2.0.0  

---

## 1. Executive Summary

Phase 02 transitions the KiranaOS architectural blueprint into a fully functional, production-ready backend, database, authentication, storage, and offline synchronization foundation.

### Core Guarantees Delivered:
1. **Multi-Tenant Data Isolation**: Database-level Row-Level Security (RLS) policies on all tables prevent any cross-shop data leaks.
2. **Local-First Speed & Durability**: Drift SQLite ORM delivers `<15ms` barcode lookups and atomic local transactions.
3. **Deterministic Idempotency**: Offline mutations carry client-generated UUID v4 `operation_id`s, ensuring network retries cannot duplicate revenue, payments, or stock decrements.
4. **Resilient Sync Engine**: Background worker with exponential backoff schedule (2s, 4s, 8s, 16s, capped at 60s, max 5 attempts) and classification of permanent vs. temporary failures.
5. **Zero Secrets in Client**: Flutter and web clients operate strictly with public credentials (`SUPABASE_URL`, `SUPABASE_ANON_KEY`); all sensitive keys and service roles remain server-side.

---

## 2. PostgreSQL Schema & Migrations (`supabase/migrations/`)

| Migration File | Description | Core Tables & Entities |
| :--- | :--- | :--- |
| `001_initial_schema.sql` | Multi-tenant schema with UTC timestamps and Paise integer math. | `shops`, `shop_users`, `roles`, `permissions`, `role_permissions`, `categories`, `brands`, `units`, `products`, `product_barcodes`, `product_images`, `price_history`, `stock_batches`, `inventory_movements`, `suppliers`, `purchases`, `purchase_items`, `supplier_payments`, `customers`, `credit_transactions`, `bills`, `bill_items`, `bill_returns`, `bill_return_items`, `payments`, `expense_categories`, `expenses`, `notifications`, `audit_logs`, `sync_operations`. |
| `002_indexes_and_constraints.sql` | Integrity constraints and high-speed composite/trigram indexes. | CHECK constraints for non-negative financial values; GIN trigram indexes on product names and customer names; composite indexes on `(shop_id, barcode)`, `(shop_id, phone)`, `(shop_id, created_at)`. |
| `003_rls_security_policies.sql` | Zero-trust PostgreSQL Row-Level Security policies. | `get_user_shop_ids()` and `user_has_shop_role()` helper functions; tenant isolation on all tables for SELECT, INSERT, UPDATE, DELETE. |
| `004_rpc_functions.sql` | Atomic server-side stored procedures. | `create_bill_atomic` (bill creation + stock decrement), `record_credit_transaction_atomic` (customer debt update), `process_sync_batch` (idempotent batch sync). |
| `005_storage_and_media.sql` | Supabase Storage configuration for product media. | `products` bucket (5MB limit, JPG/PNG/WebP); tenant-isolated upload/read/delete policies at `products/{shop_id}/{product_id}/{filename}`. |
| `seed.sql` | Safe development seed data. | System roles (`owner`, `manager`, `cashier`, `inventory_staff`) and granular permission catalog. |

---

## 3. Flutter Local Database (Drift SQLite)

The local SQLite persistence layer in `lib/database/drift/` provides reactive, zero-latency caching:

- **Tables**: `shops`, `products`, `product_barcodes`, `categories`, `customers`, `bills`, `bill_items`, `payments`, `credit_transactions`, `inventory_movements`, `sync_queue`.
- **DAOs**:
  - `ProductsDao`: Indexed barcode lookup (`getProductByBarcode`), product catalog stream.
  - `CustomersDao`: Customer search stream, atomic credit payment recording with sync queueing.
  - `BillingDao`: Local invoice creation, active bill items, transaction finalization.
  - `CategoriesDao`: Category ordering and local caching.
  - `SyncDao`: Pending operation batch query, retry tracking, failure marking, and live pending count stream.

---

## 4. Repository & Data Source Layer

```text
Feature Domain
     │
     ▼
Repository Interface (e.g. ProductRepository, CustomerRepository, AuthRepository)
     │
     ▼
Repository Implementation (e.g. ProductRepositoryImpl)
     │
 ┌───┴──────────────────────┐
 │                          │
 ▼                          ▼
Local Data Source          Remote Data Source
(Drift SQLite DAOs)        (Supabase PostgREST & RPC)
```

- **Read Policy**: Read Local First (`Drift SQLite`).
- **Mutation Policy**: Atomic Local ACID Write + Enqueue `SyncQueue` operation.
- **Sync Policy**: Background worker pushes queued operations to Supabase without blocking UI threads.

---

## 5. Offline Sync Engine & Idempotency Pipeline

- **Sync Queue Table**: Durably stores `operation_id`, `shop_id`, `entity_type`, `operation_type`, `payload`, `created_at`, `retry_count`, `last_error`, `status`.
- **Exponential Backoff**:
  - Attempt 1: Immediate on reconnection
  - Attempt 2: 2s
  - Attempt 3: 4s
  - Attempt 4: 8s
  - Attempt 5: 16s
  - Attempt 6+: 60s cap (Max 5 retries before requiring user review)
- **Conflict Resolution**:
  - Products: Last-Write-Wins (LWW) via UTC timestamps.
  - Inventory: Delta-based additive adjustments.
  - Credit: Ledger summation ($\sum\text{Credits} - \sum\text{Payments}$).
  - Bills: Immutable deduplication (`ON CONFLICT (id) DO NOTHING`).

---

## 6. Automated Verification Matrix

| Verification Suite | Test Count | Status | Description |
| :--- | :---: | :---: | :--- |
| **Drift In-Memory SQLite** | 4 | ✅ Passed | Product insert, sub-15ms barcode lookup, customer credit payment, sync queue state transitions. |
| **Sync Engine & Retry** | 5 | ✅ Passed | Exponential backoff progression, permanent failure classification, LWW, stock delta math, ledger summation. |
| **Security & RBAC** | 3 | ✅ Passed | Multi-shop tenant isolation, cashier PIN requirements for bill cancellation, profit margin masking. |
| **Product Repository** | 1 | ✅ Passed | Local-first creation, immediate local lookup, atomic sync queueing. |
| **Pure Dart Contracts** | 4 | ✅ Passed | Integer paise financial math, 0% / 5% / 18% GST calculation decomposition. |
| **Core Invariants** | 6 | ✅ Passed | Indian Rupee formatting, `Result<T>` pattern, ID generation, animation duration bounds. |

---

## 7. Phase 03 Handoff Plan

Phase 03 will build upon this verified data foundation:

1. **Authentication UI & Flow**: Supabase Email/Password login, registration, password recovery screens connected to `authNotifierProvider`.
2. **Shop Setup & Onboarding Wizard**: Store name, GSTIN, FSSAI, address, UPI ID setup with atomic remote shop creation.
3. **Terminal Cashier Quick PIN**: 4-digit PIN lock screen with auto-lock timeout.
4. **Live Dashboard**: Real-time sales metrics, pending sync indicator badge, and responsive navigation shell.
