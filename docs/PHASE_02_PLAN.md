# Phase 02 Implementation Plan — KiranaOS

**Document Version**: 1.0.0  
**Phase 01 Deliverables**: Architecture, Documentation, Database Schemas, Clean Layering, Design Tokens, and Full Mobile & Web Foundations.  
**Phase 02 Focus**: End-to-End Feature Implementation, Hardware Device Integrations, and Live Testing.  

---

## 1. Phase 02 Sprint Breakdown

### Sprint 2.1: Authentication & Shop Bootstrap
- Implement Supabase Phone OTP and Email authentication flows.
- Implement Quick PIN storage and verification in `flutter_secure_storage`.
- Build Shop Onboarding Wizard (Shop Name, GSTIN, FSSAI, Address, UPI ID).

### Sprint 2.2: Master Catalog & Barcode Engine
- Connect Google MLKit camera scanner and USB/Bluetooth HID hardware barcode listeners.
- Build Product Catalog management screens with dual barcode mapping.
- Implement Loose goods fractional weight pricing calculators.
- Integrate Supabase Storage image upload with client-side WebP compression.

### Sprint 2.3: High-Speed POS Billing & Receipt Printing
- Build POS Cart with sub-15ms barcode lookup and instant item addition.
- Implement split payments (Cash, Dynamic UPI QR code generation, Udhaar/Credit).
- Integrate ESC/POS Bluetooth and USB thermal receipt printing (58mm & 80mm).
- Implement Park / Hold bill functionality.

### Sprint 2.4: Udhaar (Khata) & Customer Ledger
- Build Customer Directory and Khata credit ledger.
- Implement credit limit validation and owner PIN override dialogs.
- Create automated WhatsApp payment reminder template links.
- Implement debt recovery and partial payment workflows.

### Sprint 2.5: Real-Time Sync Engine & Cloud Persistence
- Finalize Drift `sync_queue` background worker with exponential backoff retry.
- Connect Supabase PostgREST endpoints and WebSocket Realtime change-data-capture channels.
- Implement additive stock delta conflict reconciliation.

### Sprint 2.6: Analytics, Expenses & Day-End Z-Report
- Implement daily cash drawer float and physical denomination tallying.
- Build Day-end Z-Report PDF generator.
- Implement GSTR-1 tax export reports.
- Comprehensive end-to-end integration testing across offline and online transitions.
