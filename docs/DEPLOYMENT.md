# Deployment & Infrastructure Architecture — KiranaOS

**Document Version**: 1.0.0 (Phase 01 Production Architecture)  
**Targets**: Android APK/AAB, Next.js Web on Vercel/Docker, Supabase Managed Cloud  

---

## 1. Environment Configuration Architecture

KiranaOS adopts a 3-tier environment isolation model (`dev`, `staging`, `prod`):

```
                                ┌─────────────────────────┐
                                │   .env.<environment>    │
                                └────────────┬────────────┘
                                             │
                   ┌─────────────────────────┴─────────────────────────┐
                   │                                                   │
                   ▼                                                   ▼
       ┌──────────────────────┐                             ┌──────────────────────┐
       │     Flutter App      │                             │     Next.js Web      │
       │ (--dart-define-from) │                             │   (process.env)      │
       └──────────────────────┘                             └──────────────────────┘
```

### Required Environment Keys:
```text
KIRANA_ENV=production
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...
API_TIMEOUT_MS=15000
SYNC_BATCH_SIZE=25
ENABLE_CRASH_REPORTING=true
```

---

## 2. Mobile Client Deployment (Android POS)

### 2.1 Android Build Variants
- `app-arm64-v8a-release.apk`: Optimized for modern 64-bit Android tablets and phones.
- `app-armeabi-v7a-release.apk`: Compatible with older 32-bit entry-level POS handheld terminals.
- `bundleRelease (AAB)`: Google Play Store distribution.

### 2.2 ProGuard & Code Obfuscation
Ensures proprietary offline synchronization logic, encryption helpers, and Drift SQL models are protected from reverse engineering:
```bash
flutter build appbundle --release --obfuscate --split-debug-info=./build/app/outputs/symbols
```

---

## 3. Web Back-Office Deployment (Next.js 15)

- **Platform**: Vercel Serverless Edge or Self-Hosted Docker Container.
- **Docker Production Container**:
  - Multi-stage build leveraging Node.js 22-alpine.
  - Next.js `standalone` output mode to produce a lightweight `<80MB` Docker image.

---

## 4. Supabase Database Migration & Infrastructure as Code (IaC)

- **Tooling**: Supabase CLI (`supabase migration up`).
- **Migration Directory**: `supabase/migrations/`
- Every migration is versioned with UTC timestamp prefix (e.g., `20260824000001_init_kirana_schema.sql`).
- All migrations are applied automatically during CI/CD before web or mobile client releases.
