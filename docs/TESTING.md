# Testing Strategy & Quality Assurance Architecture — KiranaOS

**Document Version**: 1.0.0 (Phase 01 Production Architecture)  
**Standard**: Test Pyramid (Unit > Widget > Integration > Contract)  

---

## 1. The KiranaOS Test Pyramid

```
                                 ┌─────────────────────────┐
                                 │    INTEGRATION TESTS    │  (10%)
                                 │  • Full POS Checkout    │
                                 │  • Offline Sync Flow    │
                                 └────────────┬────────────┘
                                              │
                                 ┌────────────▼────────────┐
                                 │      WIDGET TESTS       │  (25%)
                                 │  • Cart State UI        │
                                 │  • Payment Modal Sheet  │
                                 │  • NumPad / Keypad      │
                                 └────────────┬────────────┘
                                              │
                                 ┌────────────▼────────────┐
                                 │       UNIT TESTS        │  (65%)
                                 │  • Integer Currency Math│
                                 │  • GST Slabs Arithmetic │
                                 │  • Drift DAOs / SQLite  │
                                 │  • Sync Conflict Engine │
                                 └─────────────────────────┘
```

---

## 2. Unit Testing Strategy

### 2.1 Critical Math & Currency Invariants
- **Integer Paise Arithmetic**: Ensure exact addition, subtraction, and proportional split calculations without 1-paise discrepancy.
- **GST Calculations**:
  - Inclusive GST: $\text{Base} = \text{Total} \times \frac{100}{100 + \text{Rate}}$.
  - Exclusive GST: $\text{Tax} = \text{Base} \times \frac{\text{Rate}}{100}$.
  - Split: CGST (50%) + SGST (50%).

### 2.2 Local SQLite (Drift) Testing
- Uses in-memory SQLite (`NativeDatabase.memory()`) to execute actual SQL statements during unit tests, ensuring complete verification of constraints, unique indexes, cascade deletes, and triggers.

---

## 3. Widget & Provider Testing Strategy

Using `flutter_test` and `flutter_riverpod`:
- Override repositories with `Mocktail` mock implementations.
- Verify that tapping "+1" on a cart item updates the Riverpod state and triggers UI re-render within 1 frame.
- Verify accessibility semantic labels and high-contrast color visibility.

---

## 4. Integration Test Suites

Location: `apps/mobile/integration_test/`

### Critical Flow 1: End-to-End Offline Billing & Sync Recovery
```
1. Initialize fresh app with in-memory test database.
2. Force ConnectivityService to 'Offline'.
3. Scan product barcode "8901030383742" -> Verify item appears in cart.
4. Complete checkout via Cash ₹50.00.
5. Verify local Drift DB contains 1 bill and stock decreased by 1.
6. Verify 'sync_queue' contains 1 pending CREATE_BILL entry.
7. Restore ConnectivityService to 'Online'.
8. Trigger SyncEngine worker.
9. Verify mock Supabase endpoint receives payload with matching operation_id.
10. Verify local 'sync_queue' status updates to 'SYNCED'.
```

---

## 5. Automated CI/CD Quality Gates

Every pull request and build must pass:
1. `flutter analyze --fatal-infos` -> **0 issues**.
2. `dart format --set-exit-if-changed .` -> **0 formatting violations**.
3. `flutter test --coverage` -> **>85% coverage on Domain & Data layers**.
