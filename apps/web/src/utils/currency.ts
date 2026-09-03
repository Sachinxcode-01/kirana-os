"use client";

/**
 * KiranaOS Unified Indian Rupee (₹) Currency & Tabular Number Engine
 * Complies with strict integer-paise invariants and Indian numbering notation (Lakhs & Crores).
 */

export interface CurrencyFormatOptions {
  showSymbol?: boolean;
  showDecimals?: boolean;
  useIndianNotation?: boolean;
  spaceAfterSymbol?: boolean;
}

/**
 * Formats integer paise into Indian Rupee string (e.g., 12345678 paise -> ₹1,23,456.78)
 */
export function formatPaise(
  paise: number,
  options: CurrencyFormatOptions = {}
): string {
  const {
    showSymbol = true,
    showDecimals = true,
    spaceAfterSymbol = false,
  } = options;

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

/**
 * Formats float rupees into Indian Rupee string (e.g., 1234.5 -> ₹1,234.50)
 */
export function formatRupees(
  rupees: number,
  options: CurrencyFormatOptions = {}
): string {
  return formatPaise(Math.round(rupees * 100), options);
}

/**
 * Converts float rupees to integer paise without floating point inaccuracy
 */
export function rupeesToPaise(rupees: number): number {
  return Math.round(rupees * 100);
}

/**
 * Converts integer paise to float rupees
 */
export function paiseToRupees(paise: number): number {
  return Math.round(paise) / 100;
}

/**
 * Formats difference/discount as positive savings string (e.g. "-₹45.00" or "Save ₹45.00")
 */
export function formatSavings(savingsPaise: number): string {
  if (savingsPaise <= 0) return "₹0.00";
  return `Save ${formatPaise(savingsPaise)}`;
}
