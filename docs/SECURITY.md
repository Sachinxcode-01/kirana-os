# Security Architecture & Access Control Specification — KiranaOS

**Document Version**: 2.0.0 (Phase 02 Implemented Foundation)  
**Standards**: Zero-Trust Tenant Isolation, OWASP MASVS, Encrypted Local Storage  

---

## 1. Threat Model & Key Security Boundaries

```
[ UNTRUSTED PHYSICAL ENVIRONMENT: SHOP COUNTER ]
      │
      ├── Android Device / Shared Cashier Terminal
      │   ├── Threat: Rogue cashier snooping profit margins or editing bill history
      │   └── Mitigation: PIN lock, RBAC, immutable local append-only audit trail
      │
      ├── Local SQLite Database
      │   ├── Threat: Physical extraction of SQLite database file from rooted Android device
      │   └── Mitigation: Android Keystore / SQLCipher encryption, zero plain-text customer PII
      │
      └── Network Layer (Public Cellular / Store WiFi)
          ├── Threat: Man-in-the-Middle (MitM) inspection or tampering
          └── Mitigation: Strict HTTPS/TLS 1.3, Supabase JWT signature validation, pinned certificates
```

---

## 2. Authentication & Session Management

1. **Owner Authentication**:
   - Phone OTP via Supabase GoTrue Auth (or Email + Secure Master Password).
   - Generates asymmetric JWT access token (1-hour expiry) and durable refresh token stored in `flutter_secure_storage` (backed by Android Keystore / iOS Keychain).
2. **Cashier / Staff Quick Switching**:
   - 4-to-6 digit numeric Quick PIN.
   - PIN hashes are computed using `Argon2id` or `PBKDF2-HMAC-SHA256` with a unique shop-level salt.
   - Quick lock after 2 minutes of POS inactivity.
3. **Zero Hardcoded Secrets**:
   - `SUPABASE_SERVICE_ROLE_KEY`, Database Passwords, and SMS Gateway keys are NEVER bundled into Flutter APK/IPA binaries.
   - Mobile client only holds `SUPABASE_ANON_KEY`, with all data protected strictly by PostgreSQL Row-Level Security (RLS).

---

## 3. Role-Based Access Control (RBAC) Matrix

| Feature Action | Owner (`owner`) | Store Manager (`manager`) | Cashier (`cashier`) |
| :--- | :---: | :---: | :---: |
| **Create & Print POS Bill** | ✅ Allowed | ✅ Allowed | ✅ Allowed |
| **Apply Discount (<10%)** | ✅ Allowed | ✅ Allowed | ✅ Allowed |
| **Apply Discount (>10%)** | ✅ Allowed | ✅ Allowed | 🔒 Owner PIN Required |
| **Cancel / Void Saved Bill**| ✅ Allowed | ✅ Allowed | 🔒 Owner PIN Required |
| **View Cost Price & Gross Profit** | ✅ Allowed | 🔒 Configurable | ❌ Masked (****) |
| **Modify Product Selling Price** | ✅ Allowed | ✅ Allowed | ❌ Denied |
| **Receive Udhaar Khata Payment** | ✅ Allowed | ✅ Allowed | ✅ Allowed |
| **Write off Customer Bad Debt** | ✅ Allowed | ❌ Denied | ❌ Denied |
| **Export GSTR-1 GST Returns** | ✅ Allowed | ✅ Allowed | ❌ Denied |
| **Add / Remove Staff Members** | ✅ Allowed | ❌ Denied | ❌ Denied |
| **Edit UPI ID / Bank Settlement Details** | ✅ Allowed | ❌ Denied | ❌ Denied |

---

## 4. Immutable Audit Logging Specification

Every sensitive business operation writes an immutable record to `audit_logs` in PostgreSQL:

```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    actor_id UUID NOT NULL REFERENCES auth.users(id),
    actor_role VARCHAR(20) NOT NULL,
    action VARCHAR(50) NOT NULL, -- e.g. 'PRICE_OVERRIDE', 'BILL_VOIDED', 'STOCK_ADJUST'
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    old_value JSONB,
    new_value JSONB,
    ip_address VARCHAR(45),
    client_timestamp TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_audit_shop_actor ON audit_logs(shop_id, actor_id, created_at DESC);
```

### Mandated Audit Triggers:
1. Selling price edited below purchase cost.
2. Bill cancelled after receipt printing.
3. Manual stock write-down due to breakage or spoilage.
4. Credit limit increased above default ₹5,000 threshold.
5. Cash drawer float adjustment.
