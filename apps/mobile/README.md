# 📱 KiranaOS Mobile — Retail POS & Terminal Client

[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Drift SQLite](https://img.shields.io/badge/Drift-SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://drift.simonbinder.eu)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.x-00599C?style=for-the-badge)](https://riverpod.dev)

The **KiranaOS Mobile Terminal Client** is an offline-first, sub-15ms Point of Sale (POS) and inventory application engineered for Android POS terminals, tablets, and Windows/Linux desktop checkout counters.

---

## 🏛️ Clean Architecture & Directory Structure

```text
apps/mobile/lib/
├── main.dart                          # App Entry Point & ProviderScope Bootstrapper
├── app/                               # Root App Theme, Environment Config & GoRouter Setup
│   ├── app.dart                       # Root Widget (MaterialApp.router)
│   ├── app_config.dart                # Dev/Staging/Prod Tokens & Service Thresholds
│   ├── app_providers.dart             # Top-Level DI Providers (Supabase, Drift DB, Storage)
│   └── router.dart                    # Declarative Router Guards & Screen Navigation Trees
│
├── core/                              # Global Infrastructure & Design System
│   ├── animation/                     # 60fps Purposeful Micro-Animations
│   ├── errors/                        # Functional Result<T> Monad & Failure Hierarchy
│   ├── extensions/                    # BuildContext, Num, and String Extension Methods
│   ├── network/                       # Connectivity Monitor & Supabase PostgREST Client
│   ├── services/                      # Indian Pincode Validation & Geolocation Services
│   ├── storage/                       # Encrypted Secure Storage & WebP Image Caching
│   ├── sync/                          # 2-Way Offline-to-Cloud Sync Engine & Retry Policies
│   ├── theme/                         # Material 3 Kirana Emerald & Amber Design System Tokens
│   ├── utils/                         # Zero-Float Currency Formatter, Logger, Tax Calculator
│   └── widgets/                       # Reusable UI Primitives (Buttons, Inputs, Skeletons)
│
├── database/                          # Drift SQLite Local Persistence
│   ├── converters/                    # Custom JSON Map Converters for SQLite
│   └── drift/                         # Drift Database Class, DAOs, and SQLite Tables
│       ├── daos/                      # Billing, Categories, Customers, Products & Sync DAOs
│       └── tables/                    # SQLite Schemas (Products, Bills, Customers, Sync Queue)
│
└── features/                          # 24 Self-Contained Domain Feature Modules
    ├── auth/                          # Phone OTP & Multi-Staff PIN Security
    ├── barcode/                       # Hardware USB/Bluetooth & Google MLKit Scanning
    ├── billing/                       # High-Speed POS Cart, Tax Calculation & Park Bill
    ├── categories/                    # Product Category Management
    ├── credit/                        # Udhaar (Khata) Ledger & Credit Limits
    ├── customers/                     # Customer Directory & Purchase History
    ├── dashboard/                     # Real-time Sales Metrics & Cashier Session Header
    ├── expenses/                      # Store Expense & Petty Cash Outlay Logging
    ├── inventory/                     # Real-time Stock Levels, Adjustments & Low Stock Alerts
    ├── invoices/                      # Thermal Receipt Viewing & Digital Receipts
    ├── notifications/                 # System Alert Queue & Overdue Payment Notifications
    ├── onboarding/                    # First-Time Store Provisioning Setup Wizard
    ├── payments/                      # Dynamic UPI Bharat QR Code Generator & Split Pay
    ├── products/                      # Master Product Catalog, Loose Weights & WebP Picker
    ├── profile/                       # Store Profile & Business Identity Settings
    ├── purchases/                     # Inward Stock Orders & Supplier Invoice Processing
    ├── receipts/                      # ESC/POS Thermal Bluetooth/USB Printing & PDF Export
    ├── reports/                       # Day-End Z-Report Cash Reconciliation & Fast Sellers
    ├── returns/                       # Bill Returns & Item Refund Processing
    ├── settings/                      # Printer Setup, Barcode Guns & Backup Tools
    ├── shop/                          # Multi-Tenant Shop Identity Management
    ├── splash/                        # App Boot & Session Verification Screen
    ├── staff/                         # Multi-Staff RBAC Management & PIN Assignment
    └── suppliers/                     # Vendor Directory & Purchase Ledgers
```

---

## ⚡ Setup & Development Guidelines

### Prerequisites
- **Flutter SDK**: `>= 3.24.0`
- **Dart SDK**: `>= 3.5.0`
- **Android Studio / VS Code** with Flutter & Dart Plugins

### Execution Commands

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate Drift ORM code and models
dart run build_runner build --delete-conflicting-outputs

# 3. Verify static code quality
flutter analyze

# 4. Run automated test suite (Unit, DAO, Widget tests)
flutter test

# 5. Launch mobile/desktop terminal application
flutter run
```

