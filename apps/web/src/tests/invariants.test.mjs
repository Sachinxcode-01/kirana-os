import test from "node:test";
import assert from "node:assert/strict";

// 1. Indian Currency Formatting Invariants
function formatPaise(paise, options = {}) {
  const { showSymbol = true, showDecimals = true, spaceAfterSymbol = false } = options;
  const isNegative = paise < 0;
  const absPaise = Math.abs(Math.round(paise));
  const rupees = absPaise / 100;

  const formattedNumber = rupees.toLocaleString("en-IN", {
    minimumFractionDigits: showDecimals ? 2 : 0,
    maximumFractionDigits: showDecimals ? 2 : 0,
  });

  const symbol = showSymbol ? (spaceAfterSymbol ? "₹ " : "₹") : "";
  const sign = isNegative ? "-" : "";

  return `${sign}${symbol}${formattedNumber}`;
}

// 2. Denomination Calculator
function calculateDenominations(changeAmount) {
  if (changeAmount <= 0) return [];
  const notes = [500, 200, 100, 50, 20, 10, 5, 2, 1];
  const breakdown = [];
  let remaining = Math.round(changeAmount);

  for (const note of notes) {
    if (remaining >= note) {
      const count = Math.floor(remaining / note);
      breakdown.push({ note, count });
      remaining %= note;
    }
  }
  return breakdown;
}

// 3. EAN-13 Checksum Validator
function isValidEan13(barcode) {
  if (!/^\d{13}$/.test(barcode)) return false;
  let sum = 0;
  for (let i = 0; i < 12; i++) {
    const digit = parseInt(barcode[i], 10);
    sum += i % 2 === 0 ? digit : digit * 3;
  }
  const checksum = (10 - (sum % 10)) % 10;
  return checksum === parseInt(barcode[12], 10);
}

// 4. POS Cart GST & Round-Off Engine
function calculateCartTotals(cartItems) {
  const subtotalPaise = cartItems.reduce((acc, item) => acc + item.unitPricePaise * item.quantity, 0);
  const mrpTotalPaise = cartItems.reduce((acc, item) => acc + item.mrpPaise * item.quantity, 0);
  const totalSavingsPaise = Math.max(0, mrpTotalPaise - subtotalPaise);

  const totalTaxPaise = cartItems.reduce((acc, item) => {
    if (item.taxRate <= 0) return acc;
    const itemTotal = item.unitPricePaise * item.quantity;
    const tax = Math.round((itemTotal * item.taxRate) / (100 + item.taxRate));
    return acc + tax;
  }, 0);

  const cgstPaise = Math.round(totalTaxPaise / 2);
  const sgstPaise = totalTaxPaise - cgstPaise;

  const rawTotal = subtotalPaise;
  const roundedRupees = Math.round(rawTotal / 100);
  const finalGrandTotalPaise = roundedRupees * 100;
  const roundOffPaise = finalGrandTotalPaise - rawTotal;

  return {
    subtotalPaise,
    mrpTotalPaise,
    totalSavingsPaise,
    totalTaxPaise,
    cgstPaise,
    sgstPaise,
    finalGrandTotalPaise,
    roundOffPaise,
  };
}

// ---------------- TESTS ---------------- //

test("1. Indian Rupee Formatter: Converts Paise to Indian notation without floating precision errors", () => {
  assert.equal(formatPaise(12345678), "₹1,23,456.78");
  assert.equal(formatPaise(24500), "₹245.00");
  assert.equal(formatPaise(0), "₹0.00");
  assert.equal(formatPaise(-185000), "-₹1,850.00");
});

test("2. Denomination Engine: Optimal physical currency notes breakdown", () => {
  // Return ₹160 change
  const breakdown160 = calculateDenominations(160);
  assert.deepEqual(breakdown160, [
    { note: 100, count: 1 },
    { note: 50, count: 1 },
    { note: 10, count: 1 },
  ]);

  // Return ₹340 change
  const breakdown340 = calculateDenominations(340);
  assert.deepEqual(breakdown340, [
    { note: 200, count: 1 },
    { note: 100, count: 1 },
    { note: 20, count: 2 },
  ]);
});

test("3. Retail Barcode Format: EAN-13 Checksum Verification", () => {
  // Valid Indian FMCG Barcodes
  assert.equal(isValidEan13("8901030383793"), true); // Aashirvaad Atta
  assert.equal(isValidEan13("8901030010323"), true); // Brooke Bond Red Label Tea
  assert.equal(isValidEan13("8901030431203"), true); // Surf Excel
  // Corrupted checksum
  assert.equal(isValidEan13("8901030383799"), false);
  // Invalid length
  assert.equal(isValidEan13("12345"), false);
});

test("4. POS Cart Math: Invariant precision, GST breakdown, and Round-Off", () => {
  const sampleCart = [
    {
      id: "item-1",
      name: "Atta 5kg",
      unitPricePaise: 24500, // ₹245.00
      mrpPaise: 26000,       // ₹260.00
      quantity: 2,
      taxRate: 0.0,
    },
    {
      id: "item-2",
      name: "Surf Excel 1kg",
      unitPricePaise: 14050, // ₹140.50
      mrpPaise: 15500,       // ₹155.00
      quantity: 1,
      taxRate: 18.0,
    },
  ];

  const totals = calculateCartTotals(sampleCart);

  // Subtotal = 2 * 24500 + 14050 = 49000 + 14050 = 63050 paise (₹630.50)
  assert.equal(totals.subtotalPaise, 63050);

  // MRP Total = 2 * 26000 + 15500 = 67500 paise (₹675.00)
  assert.equal(totals.mrpTotalPaise, 67500);

  // Savings = 67500 - 63050 = 4450 paise (₹44.50)
  assert.equal(totals.totalSavingsPaise, 4450);

  // Tax = 14050 * 18 / 118 = 2143.22 -> 2143 paise
  assert.equal(totals.totalTaxPaise, 2143);
  assert.equal(totals.cgstPaise + totals.sgstPaise, totals.totalTaxPaise);

  // Grand Total rounded to nearest ₹1: 63050 -> 63100 paise (₹631.00)
  assert.equal(totals.finalGrandTotalPaise, 63100);
  assert.equal(totals.roundOffPaise, 50); // +50 paise adjustment
});

test("5. Khata Debt Ledger: Non-negative balance and credit limit checks", () => {
  const customer = {
    creditLimitPaise: 500000, // ₹5,000.00
    currentBalancePaise: 185000, // ₹1,850.00
  };

  const newBillAmountPaise = 200000; // ₹2,000.00
  const updatedBalancePaise = customer.currentBalancePaise + newBillAmountPaise;

  assert.equal(updatedBalancePaise <= customer.creditLimitPaise, true);
  assert.equal(updatedBalancePaise, 385000); // ₹3,850.00

  // Excess charge beyond credit limit
  const excessBillPaise = 200000;
  const breachBalancePaise = updatedBalancePaise + excessBillPaise;
  assert.equal(breachBalancePaise > customer.creditLimitPaise, true); // 585000 > 500000 (Blocked)
});
