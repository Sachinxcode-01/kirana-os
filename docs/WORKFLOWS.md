# Core Business Workflows — KiranaOS

**Document Version**: 1.0.0 (Phase 01 Production Architecture)  

---

## 1. Fast Barcode Billing Workflow (Sub-50ms Transaction)

```mermaid
sequenceDiagram
    autonumber
    actor Customer
    actor Cashier
    participant Gun as Hardware Scanner (USB/Bluetooth)
    participant UI as POS Cart Screen
    participant DB as Local SQLite (Drift)
    participant Printer as ESC/POS Thermal Printer

    Customer->>Cashier: Places items on counter
    loop For each item
        Cashier->>Gun: Scans Barcode (e.g. 8901491101837)
        Gun->>UI: Emits key strokes + 'Enter'
        UI->>DB: Query Product by Barcode (<15ms)
        alt Barcode Found
            DB-->>UI: Return SKU (Maggi 70g @ ₹14.00)
            UI->>UI: Increment cart count or append row
            UI->>UI: Play high-pitch confirmation beep
        else Barcode Not Found
            UI->>UI: Play warning tone & show Quick Add Bottom Sheet
            Cashier->>UI: Enters name + price (e.g. "Local Bread ₹25")
            UI->>DB: Save as Temporary/New SKU
            UI->>UI: Append to cart
        end
    end

    Cashier->>UI: Presses 'F12' or taps 'PAY (₹140.00)'
    UI->>UI: Display Payment Method Modal
    
    alt Customer Pays UPI QR
        UI->>UI: Generate Dynamic BharatPe/UPI QR with exact ₹140.00 payload
        Customer->>Customer: Scans QR with PhonePe/GPay & Pays
        Cashier->>UI: Taps 'Confirm Received'
    else Customer Pays Cash
        Cashier->>UI: Taps 'Exact Cash' (or enters ₹200 -> displays Change ₹60)
    else Customer Pays on Udhaar (Credit)
        Cashier->>UI: Selects Customer "Ramesh Bhai" -> Balance checked against Limit
    end

    rect rgb(240, 255, 240)
        Note over UI,DB: ACID Commit: Bill + Items + Stock Decrement + Sync Queue
        UI->>DB: Commit Bill Transaction
    end

    UI->>Printer: Dispatch ESC/POS raw bytes via Bluetooth/USB
    Printer-->>Customer: Cuts 58mm Thermal Bill
    UI->>UI: Reset cart for next customer in 0ms
```

---

## 2. Udhaar (Khata / Credit) Ledger Workflow

```mermaid
flowchart TD
    A[Customer Selects Credit Payment] --> B[Search Customer by Name / Phone]
    B --> C{Customer Exists?}
    C -->|No| D[Quick Create Customer with Phone Number]
    C -->|Yes| E[Check Current Debt vs. Credit Limit]
    D --> E
    E -->|Exceeds Limit| F[Require Shop Owner PIN Override]
    E -->|Within Limit| G[Authorize Credit Bill]
    F -->|PIN Approved| G
    F -->|PIN Denied| H[Require Partial Cash/UPI Payment]
    G --> I[Record Bill as 'unpaid_credit']
    I --> J[Insert Record in `credit_transactions` as 'credit_given']
    J --> K[Update Customer `current_debt_paise`]
    K --> L[Generate WhatsApp Statement Notification Link]
```

### Udhaar Debt Recovery Process:
1. Shopkeeper opens `/credit` or customer detail `/customers/:id`.
2. Taps **"Receive Payment"** -> Enters amount collected (e.g., ₹500 against ₹1,200 total debt).
3. Selects receiving mode (**Cash** or **UPI**).
4. System records `credit_transactions` row (`payment_received`), decrements `current_debt_paise`.
5. Auto-generates WhatsApp confirmation message:
   > *"Namaste Ramesh Bhai, received ₹500.00 at Gupta General Store. Your updated balance is ₹700.00. Thank you!"*

---

## 3. Loose Goods & Fractional Weight Pricing Workflow

For unpackaged commodities (e.g. Rice, Sugar, Dals, Oil):
- **Pricing by Base Unit**: Configured as ₹48.00 / 1 kg (Paise: `4800` per `1.000` kg).
- **Cart Entry**:
  - Cashier enters weight in grams (e.g., `350g` = `0.350` kg).
  - Formula: `Total Paise = (Base Price Paise * Quantity Milligrams) / 1000000`.
  - Rounded to nearest integer paise: `(4800 * 350000) / 1000000 = 1680 Paise = ₹16.80`.

---

## 4. Day-End Cash Drawer Reconciliation (Z-Report)

At the end of each business day:
1. **Opening Float Balance**: Cash in drawer at start of day (e.g. ₹2,000.00).
2. **Cash Inflows**:
   - Total Cash Sales (e.g. ₹18,450.00).
   - Cash Debt Recoveries (e.g. ₹3,200.00).
3. **Cash Outflows**:
   - Daily Cash Expenses (Tea, Transport, Supplier cash payouts) (e.g. ₹1,150.00).
   - Cash Vendor Advances (e.g. ₹2,000.00).
4. **Calculated Closing Cash**:
   $$\text{Expected Cash} = \text{Opening} + \text{Cash Sales} + \text{Recoveries} - \text{Expenses} - \text{Inward Outflows}$$
   $$\text{Expected} = 2000 + 18450 + 3200 - 1150 - 2000 = ₹20,500.00$$
5. **Physical Count Entry**: Cashier enters actual currency note denominations (e.g., $10 \times ₹500$, $40 \times ₹200$, etc.).
6. **Variance Calculation**: $\text{Variance} = \text{Actual Count} - \text{Expected}$.
7. **Z-Report Generated & Locked**: Snapshot saved and synced to owner dashboard.
