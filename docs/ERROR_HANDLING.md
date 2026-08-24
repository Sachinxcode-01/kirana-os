# Error Handling & Failure Hierarchy — KiranaOS

**Document Version**: 2.0.0 (Phase 02 Implemented Foundation)  
**Standard**: Functional Result Pattern (`Result<T, Failure>`), Zero Unhandled Exceptions  

---

## 1. Architectural Philosophy

1. **No Silent Failures**: Every error must be explicitly captured, categorized, and logged or presented.
2. **User-Centric Messaging**: Shopkeepers never see raw stack traces, database foreign key constraints, or HTTP 500 status codes. Errors must answer:
   - What happened?
   - Can billing continue?
   - What can the user do right now? (e.g. *Tap Retry*, *Check Bluetooth Printer*, *Override with PIN*).
3. **Type-Safe Domain Modeling**: The domain layer does not throw unchecked runtime exceptions; it returns a typed `Result<T, Failure>`.

---

## 2. The `Failure` & `AppException` Taxonomy

```
                              ┌─────────────────────────┐
                              │         Failure         │
                              │   (Abstract Base Class) │
                              └────────────┬────────────┘
                                           │
          ┌────────────────────────────────┼────────────────────────────────┐
          │                                │                                │
┌─────────▼─────────┐            ┌─────────▼─────────┐            ┌─────────▼─────────┐
│   NetworkFailure  │            │   DatabaseFailure │            │   BarcodeFailure  │
│ • NoConnection    │            │ • LocalCorrupt    │            │ • ScanTimeout     │
│ • Timeout         │            │ • UniqueViolation │            │ • FormatInvalid   │
│ • ServerError     │            │ • DiskFull        │            │ • NotFound        │
└───────────────────┘            └───────────────────┘            └───────────────────┘
          │                                │                                │
┌─────────▼─────────┐            ┌─────────▼─────────┐            ┌─────────▼─────────┐
│     AuthFailure   │            │   PaymentFailure  │            │   HardwareFailure │
│ • InvalidCreds    │            │ • UpiTimeout      │            │ • PrinterOffline  │
│ • SessionExpired  │            │ • LimitExceeded   │            │ • PaperOut        │
│ • Unauthorized    │            │ • SplitMismatch   │            │ • BluetoothDown   │
└───────────────────┘            └───────────────────┘            └───────────────────┘
```

---

## 3. The `Result<S, F>` Functional Contract

```dart
/// Encapsulates either a successful value of type [S] or a failure of type [F].
sealed class Result<S, F extends Failure> {
  const Result();

  bool get isSuccess => this is Success<S, F>;
  bool get isFailure => this is ErrorResult<S, F>;

  S? get dataOrNull => switch (this) {
        Success(data: final d) => d,
        ErrorResult() => null,
      };

  F? get failureOrNull => switch (this) {
        Success() => null,
        ErrorResult(failure: final f) => f,
      };

  R fold<R>(R Function(S data) onSuccess, R Function(F failure) onFailure) {
    return switch (this) {
      Success(data: final d) => onSuccess(d),
      ErrorResult(failure: final f) => onFailure(f),
    };
  }
}

final class Success<S, F extends Failure> extends Result<S, F> {
  final S data;
  const Success(this.data);
}

final class ErrorResult<S, F extends Failure> extends Result<S, F> {
  final F failure;
  const ErrorResult(this.failure);
}
```

---

## 4. UI Error Presentation Rules

| Failure Subtype | In-App Presentation Pattern | Recommended User Action |
| :--- | :--- | :--- |
| **`BarcodeNotFoundFailure`** | Modal Bottom Sheet ("New Item Scanned") | Pre-fills barcode, prompts for Item Name & Price to immediately add to cart. |
| **`PrinterOfflineFailure`** | Yellow Warning Banner + Audio Chime | "Printer offline. Bill saved. Tap to reconnect Bluetooth." |
| **`CreditLimitExceededFailure`** | Dialog with Owner Override | "Customer limit is ₹5,000 (Current ₹5,400). Enter Owner PIN to allow." |
| **`SyncFailure`** | Persistent Connectivity Status Pill | Non-intrusive `🟡 Sync Queued (3)` — billing proceeds normally. |
| **`SessionExpiredFailure`** | Full Screen PIN Unlock Dialog | Retains in-memory cart state; unlocks immediately on valid PIN. |
