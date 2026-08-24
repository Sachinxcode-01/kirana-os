# Architecture Blueprint — KiranaOS

**Document Version**: 1.0.0 (Phase 01 Production Architecture)  
**Standard**: Clean Architecture + Feature-First (Modular Domain-Driven Design)  

---

## 1. Architectural Philosophy

KiranaOS enforces strict architectural isolation through **Clean Architecture + Feature-First Organization**. The system separates business rules from frameworks, database drivers, UI toolkits, and network libraries.

```
                    ┌──────────────────────────────────────────────┐
                    │               PRESENTATION LAYER             │
                    │   • Screens (Stateful / Stateless Views)     │
                    │   • Widgets (Dumb / Reusable Components)     │
                    │   • Providers / Notifiers (State Holders)    │
                    └──────────────────────┬───────────────────────┘
                                           │ Calls Use Cases / Watches Streams
                                           ▼
                    ┌──────────────────────────────────────────────┐
                    │                  DOMAIN LAYER                │
                    │   • Entities (Pure Dart Plain Objects)       │
                    │   • Repository Contracts (Interfaces)        │
                    │   • Use Cases (Interactors / Business Logic) │
                    │   • Value Objects & Business Exceptions      │
                    └──────────────────────▲───────────────────────┘
                                           │ Implements Interfaces
                                           │
                    ┌──────────────────────┴───────────────────────┐
                    │                   DATA LAYER                 │
                    │   • Repository Implementations               │
                    │   • Data Sources (Drift Local & Supabase API)│
                    │   • Models / DTOs & JSON Converters          │
                    │   • Mappers (Model <-> Entity <-> Table)     │
                    └──────────────────────────────────────────────┘
```

---

## 2. Directory Structure & Layout

### 2.1 Monorepo Root Layout
```text
kirana-os/
├── apps/
│   ├── mobile/                    # Production Flutter POS Application (Android / iOS / Tablet)
│   │   ├── android/
│   │   ├── ios/
│   │   ├── assets/
│   │   │   ├── icons/
│   │   │   ├── images/
│   │   │   └── audio/             # Feedback beeps & success chimes
│   │   ├── lib/
│   │   │   ├── main.dart          # Entry point & global bootstrap
│   │   │   ├── app/               # App configuration, router, root providers
│   │   │   ├── core/              # Reusable cross-feature infrastructure
│   │   │   ├── database/          # Drift SQLite ORM, DAOs, converters
│   │   │   └── features/          # 20 distinct modular business features
│   │   ├── test/                  # Unit, widget, and repository tests
│   │   └── pubspec.yaml
│   │
│   └── web/                       # Next.js 15 Web/Desktop Management Portal
│       ├── src/
│       │   ├── app/               # App Router pages & server routes
│       │   ├── components/        # UI components & Data grids
│       │   ├── lib/               # Supabase client & utilities
│       │   └── types/             # Web TypeScript types
│       ├── package.json
│       └── tsconfig.json
│
├── packages/
│   └── core_contracts/            # Shared business contracts & integer math
│
└── docs/                          # Complete architectural documentation suite
```

---

## 3. Feature-First Layer Specifications

Every one of the 20 feature packages in `apps/mobile/lib/features/` adheres to the exact same 3-tier structure:

```text
features/<feature_name>/
├── data/
│   ├── datasources/
│   │   ├── <feature_name>_local_datasource.dart    # Drift SQLite queries via DAO
│   │   └── <feature_name>_remote_datasource.dart   # Supabase REST / RPC client
│   ├── models/
│   │   └── <feature_name>_model.dart               # DTO with fromJson / toJson / toEntity
│   └── repositories/
│       └── <feature_name>_repository_impl.dart     # Implements Domain interface
│
├── domain/
│   ├── entities/
│   │   └── <feature_name>.dart                     # Pure immutable business entity
│   ├── repositories/
│   │   └── <feature_name>_repository.dart          # Abstract interface definition
│   └── usecases/
│       ├── get_<feature_name>.dart                 # Single-purpose interactor
│       ├── create_<feature_name>.dart
│       ├── update_<feature_name>.dart
│       └── delete_<feature_name>.dart
│
└── presentation/
    ├── providers/
    │   ├── <feature_name>_notifier.dart            # Riverpod StateNotifier / AsyncNotifier
    │   └── <feature_name>_state.dart               # Freezed / Sealed UI State
    ├── screens/
    │   ├── <feature_name>_screen.dart              # Top-level route screen
    │   └── <feature_name>_detail_screen.dart
    └── widgets/
        ├── <feature_name>_card.dart                # Feature-specific widget
        └── <feature_name>_filter_sheet.dart
```

---

## 4. Core Feature Matrix (20 Production Modules)

| # | Feature Name | Core Responsibility | Local-First Offline Capability |
| :- | :--- | :--- | :--- |
| 1 | **auth** | Session tokens, Phone OTP, PIN lock, Role permissions | Cached Session + Offline PIN Verify |
| 2 | **onboarding** | Shop registration, initial tax/currency setup, staff invite | Local draft until sync |
| 3 | **dashboard** | Daily summary KPIs, cash drawer status, sync health | Computed from local Drift tables |
| 4 | **billing** | High-speed POS cart, barcode scan listener, payment trigger | 100% Offline with queue |
| 5 | **barcode** | Barcode normalization, hardware scanner & MLKit camera bridge | 100% Offline lookup |
| 6 | **products** | Product master, HSN codes, tax slabs, multi-barcodes, MRP | Full local read/write with sync |
| 7 | **categories** | Category and department hierarchy | Full local read/write with sync |
| 8 | **inventory** | Batch tracking, stock adjustments, low-stock threshold | Local real-time decrement |
| 9 | **purchases** | Supplier inward goods, purchase orders, purchase cost | Full local read/write with sync |
| 10 | **suppliers** | Supplier directory, payable balances, ledger | Full local read/write with sync |
| 11 | **customers** | Customer directory, contact info, purchase history | Full local read/write with sync |
| 12 | **credit** (Udhaar) | Customer ledger, credit limits, WhatsApp reminder links | Full local read/write with sync |
| 13 | **payments** | Cash, UPI QR, Card, Credit, Split payment records | Full local read/write with sync |
| 14 | **invoices** | ESC/POS 58mm/80mm thermal printing, PDF export, share | 100% Offline generation |
| 15 | **returns** | Item return processing, stock re-inwarding, refund notes | Full local read/write with sync |
| 16 | **expenses** | Daily operational costs (Rent, Tea, Fuel, Wages) | Full local read/write with sync |
| 17 | **reports** | Day-end Z-Report, Sales summary, GST GSTR-1 export | Generated from local database |
| 18 | **notifications**| In-app alert queue for low stock, unpaid credit, sync errors | Local trigger + Remote FCM |
| 19 | **profile** | Shop name, GSTIN, FSSAI, Address, UPI ID, logo | Cached profile in secure storage |
| 20 | **settings** | Bluetooth printer pairing, hardware scanner config, backup | Stored in SharedPreferences / Drift |

---

## 5. Dependency Rules & Architectural Invariants

1. **The Dependency Inversion Principle (DIP)**:
   - Presentation depends on Domain Use Cases and Provider contracts.
   - Domain depends on **nothing** (pure Dart SDK only; zero dependencies on Flutter UI or Drift).
   - Data depends on Domain (to implement repository interfaces).
2. **Result Pattern Everywhere**:
   - All Use Cases return `Future<Result<T, Failure>>` or `Stream<T>`.
   - Exceptions are caught and converted to `Failure` instances inside the Data layer. No unhandled raw exceptions bubble up to UI widgets.
3. **Immutability**:
   - All Domain Entities and Presentation States are immutable objects (`@freezed` or `final` fields with copyWith).
4. **Offline Isolation**:
   - Data layer repositories write directly to local Drift tables, then enqueue a record into `sync_queue`. The repository does not await cloud responses before returning success to the UI.
