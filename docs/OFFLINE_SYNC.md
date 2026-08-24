# Offline-First & Synchronization Architecture — KiranaOS

**Document Version**: 2.0.0 (Phase 02 Implemented Foundation)  
**Strategy**: Local-First ACID Writes + Background Asynchronous Idempotent Sync  

---

## 1. Core Principles

1. **Local-First Authoritative Writes**: The local Drift SQLite database is the immediate transaction authority for the POS device. All billing, stock decrements, and customer updates commit locally in `<50ms` regardless of internet presence.
2. **Deterministic Idempotency**: Every mutative sync operation is assigned a client-generated UUID `operation_id` at inception. If network timeouts cause retries, Supabase recognizes the existing `operation_id` and rejects duplicates cleanly without double-counting revenue or stock.
3. **Queue Durability**: Mutations are committed to the `sync_queue` table in the **exact same SQLite ACID transaction** as the business data. A device crash or battery death cannot result in data being saved locally without being queued for sync.

---

## 2. Sync Engine Architecture

```mermaid
flowchart TD
    subgraph Client Device (Flutter)
        UI[POS Action / Checkout] -->|Atomic Write| LocalTX[Local ACID SQLite Transaction]
        LocalTX -->|Save Data| DB[(Drift Database Tables)]
        LocalTX -->|Enlist Op| SQ[(sync_queue Table)]
        
        ConnWatcher[Connectivity Monitor] -->|Online Event| Worker[SyncEngine Worker]
        SQ -->|Fetch Oldest Pending Ops| Worker
        Worker -->|Batch HTTP POST| CloudAPI[Supabase Edge / PostgREST]
    end

    subgraph Supabase Cloud
        CloudAPI --> RLSCheck{RLS & Auth Check}
        RLSCheck -->|Authorized| DBInsert[Insert/Update Cloud PostgreSQL]
        DBInsert -->|Success 200/201| CloudAPI
    end

    CloudAPI -->|Acknowledge| Worker
    Worker -->|Mark Status = SYNCED| SQ
```

---

## 3. The `sync_queue` Local Drift Schema

```sql
CREATE TABLE sync_queue (
    operation_id TEXT PRIMARY KEY,       -- Client UUID v4 (Idempotency Key)
    shop_id TEXT NOT NULL,
    entity_type TEXT NOT NULL,          -- 'bill', 'product', 'customer', 'credit_txn'
    entity_id TEXT NOT NULL,            -- UUID of the subject record
    operation_type TEXT NOT NULL,       -- 'CREATE', 'UPDATE', 'DELETE'
    payload TEXT NOT NULL,              -- Full serialized JSON payload
    created_at INTEGER NOT NULL,        -- Epoch millis
    retry_count INTEGER NOT NULL DEFAULT 0,
    last_error TEXT,
    status TEXT NOT NULL DEFAULT 'PENDING' -- 'PENDING', 'IN_PROGRESS', 'FAILED', 'SYNCED'
);
CREATE INDEX idx_sync_queue_order ON sync_queue(created_at ASC) WHERE status = 'PENDING';
```

---

## 4. Conflict Resolution Matrix

| Entity Type | Conflict Scenario | Resolution Strategy | Rationale |
| :--- | :--- | :--- | :--- |
| **Bills & Invoices** | Duplicate upload due to network retry | **Idempotent Deduplication** (`ON CONFLICT (id) DO NOTHING`) | Financial receipts are immutable historical facts. |
| **Inventory Stock Quantity** | Two devices sell the same SKU offline simultaneously | **Delta-Based Additive Reconciliation** (`stock = stock - delta`) | Absolute value overwrites cause lost sales counts. Applying quantity deltas preserves true stock reductions. |
| **Customer Credit Balance** | Payments recorded on device while owner logs credit on web | **Ledger-Derived Reconciliation** | Balance is recomputed as $\sum(\text{Credits}) - \sum(\text{Payments})$ rather than raw scalar overwrites. |
| **Product Master (Name/Price)** | Price edited on Web and Mobile offline | **Last-Write-Wins (LWW)** using `updated_at` UTC timestamp | Most recent price change by the shop owner takes precedence. |

---

## 5. Exponential Backoff & Retry Policy

```text
Attempt 1: Immediate on network reconnection
Attempt 2: 2 seconds delay
Attempt 3: 4 seconds delay
Attempt 4: 8 seconds delay
Attempt 5: 16 seconds delay
Max Delay: 60 seconds capped
```

If an operation encounters a 4xx client validation error (e.g. invalid foreign key), it is marked as `FAILED` and quarantined with error logs, notifying the shopkeeper without blocking subsequent bills in the queue.

---

## 6. Global Connectivity Status Indicator

The UI renders an unobtrusive status pill at the top of all screens:

| State | Visual Indicator | Meaning & Behavior |
| :--- | :--- | :--- |
| **Online** | 🟢 `Online` | Fully connected to Supabase Realtime & Cloud API. |
| **Offline** | 🔴 `Offline — Billing Available` | Cellular/WiFi disconnected. All POS billing active in local SQLite. |
| **Syncing** | 🟡 `Syncing (4 bills...)` | Actively pushing local queue items to Supabase in background. |
| **Sync Warning**| ⚠️ `Sync Pending (Tap to retry)` | Network unstable or background retry in progress. |
