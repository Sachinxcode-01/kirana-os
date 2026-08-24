<div align="center">

# 🛒 KiranaOS — Offline-First Retail POS & ERP Operating System

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Drift SQLite](https://img.shields.io/badge/Drift-SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://drift.simonbinder.eu)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL_16-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Next.js 15](https://img.shields.io/badge/Next.js-15_App_Router-000000?style=for-the-badge&logo=nextdotjs&logoColor=white)](https://nextjs.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

<br/>

![KiranaOS Hero Banner](assets/banner.png)

<br/>

**KiranaOS** is a production-grade, distributed, offline-first Point of Sale (POS) and Enterprise Resource Planning (ERP) platform architected specifically for Indian retail grocery, general provision stores (Kiranas), and mini-supermarkets.

</div>

---

## 📖 Executive Summary & Vision

Traditional retail in India is powered by over 13 million neighborhood Kirana stores driving 90% of the nation's $800B+ grocery commerce. During evening peak hours (6 PM – 9 PM), store cashiers have an operational window of **2 to 5 seconds per customer item**. 

Cloud-only POS software fails in Indian retail environments due to intermittent 4G/5G connectivity, power fluctuations, and basement dead zones. **KiranaOS** solves this with a **local-first, cloud-authoritative architecture**:

- ⚡ **Zero-Latency Billing**: Local SQLite (Drift ORM) delivers item lookups in `<15ms` and local bill finalization in `<50ms`.
- 🔌 **100% Offline-First**: Continue billing, printing, stock adjustments, and Udhaar recording indefinitely without internet.
- 🔄 **2-Way Automatic Sync**: Queues mutation operations with deterministic UUID v4 idempotency keys and synchronizes to Supabase PostgreSQL when connectivity resumes.
- 🪙 **Zero Floating-Point Error Arithmetic**: Pure integer Paise math (1 INR = 100 Paise) across all calculations prevents rounding discrepancies and GST calculation drift.
- 📒 **Digital Udhaar (Khata) & WhatsApp Recovery**: Customer credit limits, transaction histories, and 1-tap WhatsApp payment reminders with dynamic UPI QR codes.
- 📊 **Day-End Z-Report**: Automated reconciliation of physical cash drawer, digital payments, supplier payouts, and credit collections.

---

## 🏛️ System Architecture

KiranaOS utilizes a dual-tier distributed topology with pure separation of concerns across Mobile/Tablet terminals and the Web Back-Office.

```
┌────────────────────────────────────────────────────────┐       ┌───────────────────────────────────────────────────────┐
│              FLUTTER CLIENT (Mobile/Tablet)            │       │               NEXT.JS WEB (Desktop Portal)            │
│                                                        │       │                                                       │
│  Presentation (Riverpod 2.x + GoRouter 14.x)           │       │  React Server Components + Client Data Grids          │
│       │                                                │       │       │                                               │
│  Domain (Pure Dart Entities & Use Cases)               │       │  Domain Actions & Server Validations                  │
│       │                                                │       │       │                                               │
│  Data Layer (Repositories + Sync Engine)               │       │  Supabase PostgREST Client + Direct SSR queries       │
│       │                                      │         │       └──────────────────────────┬────────────────────────────┘
│  Local SQLite (Drift ORM)             Supabase SDK     │                                  │
│  (Zero-latency POS Operations)        (Cloud Sync)     │                                  │
└──────────────────────────────────────────────┬─────────┘                                  │
                                               │                                            │
                                               ▼                                            ▼
                                 ┌─────────────────────────────────────────────────────────────┐
                                 │                 SUPABASE CLOUD INFRASTRUCTURE               │
                                 │                                                             │
                                 │   • PostgreSQL 16 (Authoritative Database + RLS Policies)   │
                                 │   • GoTrue Auth (JWT + Phone OTP + PIN Verification)        │
                                 │   • Realtime Engine (Change Data Capture WebSockets)        │
                                 │   • Storage Buckets (Product WebP Images with Edge CDN)     │
                                 │   • Edge Functions (WhatsApp API, PDF Receipt Generation)   │
                                 └─────────────────────────────────────────────────────────────┘
```

---

## ✨ Key Capabilities & Feature Modules

KiranaOS comes equipped with 20 modular, Clean-Architecture features:

| Feature Module | Core Functionality & Technical Implementation |
| :--- | :--- |
| **⚡ High-Speed Billing** | Real-time cart calculations, physical barcode scanner support (USB/HID & Camera via Google MLKit), loose item weight calculator, multi-item discount rules, and park/hold bills. |
| **📦 Product Catalog** | Dual-barcode management (13-digit EAN/UPC & internal SKUs), custom units (kg, g, L, ml, pcs), category taxonomies, HSN codes, and WebP product asset caching. |
| **📒 Udhaar (Credit) Ledger** | Customer Khata tracking, risk credit limits, transaction statements, partial bill settlement, and 1-tap WhatsApp payment reminders with pre-filled UPI links. |
| **💳 Payments & UPI** | Cash drawer management, dynamic on-screen Bharat QR / UPI QR code generation, split payments (Cash + UPI + Credit), and instant thermal receipt printing (ESC/POS). |
| **📊 Inventory & Batches** | Real-time stock decrement on checkout, batch expiry date tracking, minimum safety stock thresholds, and stock inwarding adjustments. |
| **🚚 Purchases & Suppliers**| Supplier directory, purchase order inwarding, purchase price vs. selling MRP margin tracking, and supplier credit balance tracking. |
| **💸 Expense Tracker** | Petty cash outlays, store rent, electricity, transport, tea/snacks, and staff salary advances deducted from daily register totals. |
| **📈 Reports & Z-Report** | Day-End Z-Report cash reconciliation, Gross Margin analysis, Fast-moving vs. Dead stock tracking, and GST Sales/Inward summaries. |
| **👥 Multi-Staff RBAC** | Owner, Store Manager, and Cashier roles with granular permissions, secure PIN overrides for bill cancellations, and audit logs. |
| **🔄 Offline Sync Engine** | Offline mutation queue, exponential backoff retries, conflict resolution policies (LWW & Invariant checking), and connection state monitor. |

---

## 🗂️ Monorepo Structure

```text
kirana-os/
├── assets/                            # Brand Visuals, Mockups & Hero Banners
│   ├── banner.png                     # 16:9 High-Resolution Professional Hero Image
│   └── kirana_os_banner.jpg           # Compressed Distribution Banner
│
├── apps/
│   ├── mobile/                        # Flutter POS & Terminal Client Application
│   │   ├── android/                   # Android Native Host Project (Build Gradle, Manifest)
│   │   ├── ios/                       # iOS Native Host Project
│   │   ├── windows/                   # Windows Desktop Native Host
│   │   ├── assets/                    # Mobile Specific Icons, Audio & Images
│   │   ├── lib/
│   │   │   ├── app/                   # App Entry, Shell Router & Theme Configuration
│   │   │   ├── core/                  # Core Theme, Errors, Network, Storage, Shared Widgets
│   │   │   │   ├── animation/         # Purposeful 60fps Micro-Animations
│   │   │   │   ├── errors/            # Functional Result<T> & Failure Hierarchy
│   │   │   │   ├── network/           # Connectivity Monitor & Supabase Client
│   │   │   │   ├── storage/           # Secure Storage & SharedPreferences
│   │   │   │   └── theme/             # Material 3 Kirana Emerald & Amber Tokens
│   │   │   ├── database/              # Drift SQLite ORM, DAOs, Tables, Type Converters
│   │   │   └── features/              # 20 Modular Domain Features (Clean Architecture)
│   │   │       ├── auth/              # Phone OTP, PIN & Session Management
│   │   │       ├── barcode/           # Hardware USB/Bluetooth & MLKit Scanning
│   │   │       ├── billing/           # Active Cart, Discounts, Tax Calculation & Park Bill
│   │   │       ├── categories/        # Master Product Categorization
│   │   │       ├── credit/            # Udhaar Ledger, Customer Limits & Reminders
│   │   │       ├── customers/         # Customer CRM & Purchase History
│   │   │       ├── dashboard/         # Real-time Sales Metrics & Quick Actions
│   │   │       ├── expenses/          # Store Expense Recording & Categorization
│   │   │       ├── inventory/         # Stock Levels, Reorder Alerts & Batch Expiries
│   │   │       ├── invoices/          # Thermal Invoice Printing & Digital Receipts
│   │   │       ├── notifications/     # Low-Stock & Payment Due Alerts
│   │   │       ├── onboarding/        # First-Time Store Setup Wizard
│   │   │       ├── payments/          # Cash Drawer, Dynamic UPI QR & Split Pay
│   │   │       ├── products/          # Master Product Catalog & Loose Pricing
│   │   │       ├── profile/           # Shop Configuration & Store Timings
│   │   │       ├── purchases/         # Inward Stock Entries & Supplier Invoices
│   │   │       ├── reports/           # Day-End Z-Report & Sales Summaries
│   │   │       ├── returns/           # Item Returns & Bill Refund Processing
│   │   │       ├── settings/          # Printer Setup, Barcode Config & Database Tools
│   │   │       └── suppliers/         # Vendor Profiles & Purchase Ledgers
│   │   └── test/                      # Unit, DAO, and Widget Test Suites
│   │
│   └── web/                           # Next.js 15 Analytics & Back-Office Web Portal
│       ├── src/
│       │   ├── app/                   # App Router Pages (Analytics, Catalog, Inventory)
│       │   └── types/                 # TypeScript Contract Definitions
│       ├── package.json
│       └── tailwind.config.ts
│
├── packages/
│   └── core_contracts/                # Pure-Dart Shared Financial & Invariant Package
│       ├── lib/
│       │   ├── currency/              # Integer Paise Arithmetic & Indian Rupee Formatter
│       │   ├── sync/                  # Sync Entity Contracts & Idempotency Key Types
│       │   └── tax/                   # GST Slabs, CGST/SGST/IGST Decomposition Services
│       └── test/                      # 100% Coverage Math & Invariant Unit Tests
│
└── docs/                              # Exhaustive Technical & Architectural Blueprint
    ├── PRD.md                         # Product Requirements Document
    ├── TRD.md                         # Technical Requirements Document
    ├── ARCHITECTURE.md                # Clean Architecture & Data Flow Guidelines
    ├── DATABASE.md                    # PostgreSQL Cloud (25+ Tables) & Drift SQLite Schema
    ├── WORKFLOWS.md                   # Barcode POS, Udhaar & Z-Report Operational Sequences
    ├── OFFLINE_SYNC.md                # 2-Way Sync Engine & Idempotency Rules
    ├── SECURITY.md                    # Supabase Auth, Row Level Security (RLS) & RBAC
    ├── ERROR_HANDLING.md              # Functional Result<T> & Failure Hierarchy
    ├── DESIGN_SYSTEM.md               # Material 3 Kirana Emerald & Amber Token System
    ├── ANIMATION_SYSTEM.md            # 60fps Purposeful Motion & Micro-Interactions
    ├── TESTING.md                     # Test Pyramid, Mocking & CI Automation
    ├── DEPLOYMENT.md                  # Android APK/AAB & Next.js CI/CD Pipeline
    └── PHASE_02_PLAN.md               # Step-by-Step Implementation Roadmap
```

---

## ⚡ Core Engineering Principles

### 1. Zero Floating-Point Arithmetic Invariant
In retail billing with percentage discounts, fractional weights (e.g. 350 grams of Basmati rice), and GST slabs (0%, 5%, 12%, 18%, 28%), standard IEEE 754 floating-point math creates cumulative rounding errors.

All financial amounts in KiranaOS are strictly represented as **Integer Paise (`BIGINT` / `int`)**:
```dart
// 1 INR = 100 Paise
final priceInPaise = 1050; // Represents ₹10.50
final totalBillPaise = 125075; // Represents ₹1,250.75

// Formatting is deferred strictly to the presentation boundary:
final formatted = IndianRupeeFormatter.format(totalBillPaise); // "₹1,250.75"
```

### 2. Functional Error Handling (`Result<T>`)
KiranaOS bans untyped runtime exceptions across business layers. All repository and domain use cases return an immutable `Result<T>`:

```dart
Future<Result<Invoice>> finalizeBill(Cart cart) async {
  try {
    final invoice = await _billingRepository.createInvoice(cart);
    return Result.ok(invoice);
  } on LocalDatabaseException catch (e) {
    return Result.fail(DatabaseFailure(e.message));
  }
}
```

### 3. Sub-15ms Barcode Search Guarantee
SQLite indexes on `product_barcodes(barcode)` and `products(name)` allow instant item resolution before the cashier's barcode gun completes its return keystroke:
```sql
CREATE INDEX idx_product_barcodes_lookup ON product_barcodes (barcode);
CREATE INDEX idx_products_search ON products (name COLLATE NOCASE);
```

---

## 🚀 Quickstart & Development Setup

### Prerequisites
- **Flutter SDK**: `>= 3.24.0` ([Install Guide](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: `>= 3.5.0`
- **Node.js**: `>= 20.0.0` & `npm` / `pnpm`
- **Supabase CLI**: (Optional, for local cloud stack)

### 1. Mobile POS Application (Flutter)

```bash
# Navigate to the mobile app directory
cd apps/mobile

# Install all Flutter and Dart dependencies
flutter pub get

# Generate Drift ORM code, DAOs, and Freezed models
dart run build_runner build --delete-conflicting-outputs

# Verify static code health (Zero Warnings Guarantee)
flutter analyze

# Run unit and widget test suites
flutter test

# Launch on connected Android device or desktop terminal
flutter run
```

### 2. Pure-Dart Core Contracts (`packages/core_contracts`)

```bash
cd packages/core_contracts

# Fetch dependencies
dart pub get

# Execute invariant financial & GST test suites
dart test
```

### 3. Web Back-Office & Analytics (`apps/web`)

```bash
cd apps/web

# Install dependencies
npm install

# Start local Next.js development server
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) to view the web management dashboard.

---

## 📊 Performance Service Level Agreements (SLAs)

| Operational Metric | Target SLA | Engineering Implementation |
| :--- | :--- | :--- |
| **Local Barcode Lookup** | `< 15ms` | Indexed Drift SQLite queries with memory caching. |
| **Cart Item Render Latency** | `< 30ms` (60fps) | Unidirectional Riverpod state stream + micro-transitions `<=150ms`. |
| **Bill Finalization Latency** | `< 50ms` | Local SQLite ACID transaction; zero network blocking. |
| **Cold Startup Time** | `< 1.2s` | Deferred background synchronization warmup. |
| **Android Memory Ceiling** | `< 120MB RSS` | WebP image memory caching & object recycling. |
| **Crash-Free Sessions** | `> 99.95%` | Functional `Result<T>` boundaries with zero uncaught async errors. |

---

## 🎨 Design System & Visual Identity

KiranaOS is built on **Material 3** principles customized with an Indian retail-focused color palette engineered for high visibility under fluorescent shop lights:

- **Kirana Emerald** (`#00897B` / `#004D40`): Primary brand color representing financial prosperity and trust.
- **Amber Gold** (`#FFB300` / `#FF8F00`): Secondary accent for promotions, alerts, and pending sync badges.
- **High-Contrast Surface** (`#121212` / `#FFFFFF`): Crisp typography and generous touch targets (`min 48dp x 48dp`) for speed.

---

## 📚 Complete Engineering Documentation

Exhaustive technical documentation is available in the [`docs/`](docs/) directory:

- 📄 [Product Requirements Document (PRD)](docs/PRD.md)
- 📄 [Technical Requirements Document (TRD)](docs/TRD.md)
- 📄 [Clean Architecture & Feature Design](docs/ARCHITECTURE.md)
- 📄 [PostgreSQL & SQLite Database Specifications](docs/DATABASE.md)
- 📄 [POS Billing, Udhaar & Z-Report Workflows](docs/WORKFLOWS.md)
- 📄 [Offline Synchronization & Conflict Resolution](docs/OFFLINE_SYNC.md)
- 📄 [Security, Row Level Security & RBAC](docs/SECURITY.md)
- 📄 [Functional Error Handling Guidelines](docs/ERROR_HANDLING.md)
- 📄 [Design System Tokens & Typography](docs/DESIGN_SYSTEM.md)
- 📄 [Animation & Micro-Interaction Guidelines](docs/ANIMATION_SYSTEM.md)
- 📄 [Testing Pyramid & Quality Assurance](docs/TESTING.md)
- 📄 [CI/CD & Deployment Procedures](docs/DEPLOYMENT.md)
- 📄 [Phase 02 Actionable Roadmap](docs/PHASE_02_PLAN.md)

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
