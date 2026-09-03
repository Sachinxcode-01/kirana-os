"use client";

import React, { useState, useEffect, useCallback, useMemo } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  Banknote,
  X,
  CheckCircle2,
  AlertCircle,
  ArrowRight,
  QrCode,
  Printer,
  Sparkles,
  BookOpen,
  RotateCcw,
  Coins,
  ReceiptText,
} from "lucide-react";

import { posAudio } from "@/utils/audioFeedback";

interface QuickTenderModalProps {
  isOpen: boolean;
  onClose: () => void;
  defaultBillAmount?: number; // In Rupees
  onSuccess?: (details: { billAmount: number; tenderReceived: number; changeReturned: number; mode: string }) => void;
  onTenderSuccess?: (mode: "CASH" | "UPI" | "UDHAAR") => void;
}

// Indian Rupee currency denominations for cash return breakdown
const CURRENCY_NOTES = [500, 200, 100, 50, 20, 10, 5, 2, 1];

export function QuickTenderModal({
  isOpen,
  onClose,
  defaultBillAmount = 340,
  onSuccess,
  onTenderSuccess,
}: QuickTenderModalProps) {
  const [billAmount, setBillAmount] = useState<number>(defaultBillAmount);
  const [tenderReceived, setTenderReceived] = useState<number>(defaultBillAmount);
  const [paymentMode, setPaymentMode] = useState<"CASH" | "UPI" | "UDHAAR">("CASH");
  const [isCompleted, setIsCompleted] = useState(false);

  useEffect(() => {
    if (isOpen) {
      setBillAmount(defaultBillAmount);
      setTenderReceived(defaultBillAmount);
      setPaymentMode("CASH");
      setIsCompleted(false);
    }
  }, [isOpen, defaultBillAmount]);

  // Calculations
  const changeReturned = Math.max(0, tenderReceived - billAmount);
  const isShort = tenderReceived < billAmount;
  const shortAmount = Math.max(0, billAmount - tenderReceived);

  // Optimal notes/coins breakdown for cashier to hand back
  const changeNotesBreakdown = useMemo(() => {
    if (changeReturned <= 0) return [];
    const breakdown: { note: number; count: number }[] = [];
    let remaining = Math.round(changeReturned);

    for (const note of CURRENCY_NOTES) {
      if (remaining >= note) {
        const count = Math.floor(remaining / note);
        breakdown.push({ note, count });
        remaining %= note;
      }
    }
    return breakdown;
  }, [changeReturned]);

  // Smart Suggested Tender Buttons (e.g. Exact, Next 100, Next 500, Next 1000)
  const smartTenderOptions = useMemo(() => {
    const opts: { label: string; amount: number; hint: string }[] = [];
    opts.push({ label: "Exact", amount: billAmount, hint: "Exact Cash" });

    const next100 = Math.ceil(billAmount / 100) * 100;
    if (next100 > billAmount && next100 <= 1000) {
      opts.push({ label: `₹${next100}`, amount: next100, hint: "Next Hundred" });
    }

    const next500 = Math.ceil(billAmount / 500) * 500;
    if (next500 > billAmount && !opts.some((o) => o.amount === next500)) {
      opts.push({ label: `₹${next500}`, amount: next500, hint: "₹500 Note" });
    }

    const next1000 = Math.ceil(billAmount / 1000) * 1000;
    if (next1000 > billAmount && next1000 <= 2000 && !opts.some((o) => o.amount === next1000)) {
      opts.push({ label: `₹${next1000}`, amount: next1000, hint: "₹1,000 Note" });
    }

    if (billAmount < 2000 && !opts.some((o) => o.amount === 2000)) {
      opts.push({ label: "₹2,000", amount: 2000, hint: "₹2,000 Note" });
    }

    return opts;
  }, [billAmount]);

  const handleAddDenomination = (value: number) => {
    posAudio.playBarcodeBeep();
    setTenderReceived((prev) => prev + value);
  };

  const handleSetExactTender = (amount: number) => {
    posAudio.playBarcodeBeep();
    setTenderReceived(amount);
  };

  const handleFinalize = useCallback(() => {
    if (isShort && paymentMode === "CASH") {
      posAudio.playWarningBuzzer();
      return;
    }

    posAudio.playSuccessChime();
    setIsCompleted(true);
    setTimeout(() => {
      onSuccess?.({
        billAmount,
        tenderReceived: paymentMode === "CASH" ? tenderReceived : billAmount,
        changeReturned: paymentMode === "CASH" ? changeReturned : 0,
        mode: paymentMode,
      });
      onTenderSuccess?.(paymentMode);
      setIsCompleted(false);
      onClose();
    }, 1100);
  }, [isShort, paymentMode, billAmount, tenderReceived, changeReturned, onSuccess, onTenderSuccess, onClose]);

  // Single-Key POS Keyboard Listener
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      // Don't intercept if user is typing numbers into an input field
      const isInput = e.target instanceof HTMLInputElement;

      if (e.key === "Escape") {
        e.preventDefault();
        onClose();
      } else if (e.key === "Enter") {
        e.preventDefault();
        handleFinalize();
      } else if (!isInput) {
        if (e.key === "1") setPaymentMode("CASH");
        if (e.key === "2") setPaymentMode("UPI");
        if (e.key === "3") setPaymentMode("UDHAAR");
        if (e.key.toLowerCase() === "e") handleSetExactTender(billAmount);
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, handleFinalize, onClose, billAmount]);

  if (!isOpen) return null;

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
          className="absolute inset-0 bg-slate-950/75 backdrop-blur-sm cursor-pointer"
        />

        {/* Modal Window */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 15 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 15 }}
          transition={{ duration: 0.2, ease: "easeOut" }}
          className="relative w-full max-w-xl bg-slate-900 border border-slate-700/80 rounded-3xl shadow-2xl overflow-hidden z-10 text-slate-100"
        >
          {/* Ambient Top Glow */}
          <div className="absolute top-0 right-1/4 w-72 h-32 bg-emerald-500/15 rounded-full blur-3xl pointer-events-none" />

          {/* Modal Header */}
          <div className="flex items-center justify-between p-5 border-b border-slate-800 relative z-10">
            <div className="flex items-center gap-3">
              <div className="p-2.5 bg-gradient-to-br from-emerald-600 to-teal-600 rounded-2xl shadow-md shadow-emerald-950/50 border border-emerald-400/30">
                <Banknote className="w-5 h-5 text-white" />
              </div>
              <div>
                <h2 className="text-base font-black text-white flex items-center gap-2">
                  <span>Quick Cash Tender &amp; Return Calculator</span>
                  <kbd className="px-1.5 py-0.5 text-[10px] font-mono font-bold rounded bg-slate-800 text-emerald-300 border border-slate-700">
                    F4
                  </kbd>
                </h2>
                <p className="text-xs text-slate-400">One-tap smart notes, auto change calculation &amp; currency breakdown</p>
              </div>
            </div>

            <button
              onClick={onClose}
              className="p-2 text-slate-400 hover:text-white rounded-xl hover:bg-slate-800 transition-colors cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Success Banner */}
          {isCompleted ? (
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              className="p-10 text-center space-y-3"
            >
              <div className="w-16 h-16 mx-auto bg-emerald-500/20 border border-emerald-500/40 rounded-full flex items-center justify-center text-emerald-400">
                <CheckCircle2 className="w-9 h-9 animate-bounce" />
              </div>
              <h3 className="text-xl font-black text-white">Payment Confirmed &amp; Bill Finalized!</h3>
              <p className="text-xs text-slate-300">
                ₹{billAmount.toFixed(2)} recorded via {paymentMode}. Printing ESC/POS receipt &amp; updating inventory...
              </p>
            </motion.div>
          ) : (
            /* Main Form */
            <div className="p-6 space-y-4">
              {/* Payment Mode 3-Way Tabs */}
              <div className="grid grid-cols-3 gap-1.5 p-1 bg-slate-950/90 rounded-2xl border border-slate-800">
                <button
                  type="button"
                  onClick={() => setPaymentMode("CASH")}
                  className={`py-2 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer ${
                    paymentMode === "CASH"
                      ? "bg-gradient-to-r from-emerald-600 to-teal-600 text-white shadow-md shadow-emerald-950/60"
                      : "text-slate-400 hover:text-slate-200"
                  }`}
                >
                  <Banknote className="w-4 h-4" />
                  <span>1. Cash</span>
                </button>
                <button
                  type="button"
                  onClick={() => setPaymentMode("UPI")}
                  className={`py-2 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer ${
                    paymentMode === "UPI"
                      ? "bg-gradient-to-r from-teal-600 to-cyan-600 text-white shadow-md shadow-teal-950/60"
                      : "text-slate-400 hover:text-slate-200"
                  }`}
                >
                  <QrCode className="w-4 h-4" />
                  <span>2. UPI QR</span>
                </button>
                <button
                  type="button"
                  onClick={() => setPaymentMode("UDHAAR")}
                  className={`py-2 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer ${
                    paymentMode === "UDHAAR"
                      ? "bg-gradient-to-r from-amber-600 to-orange-600 text-white shadow-md shadow-amber-950/60"
                      : "text-slate-400 hover:text-slate-200"
                  }`}
                >
                  <BookOpen className="w-4 h-4" />
                  <span>3. Khata (Udhaar)</span>
                </button>
              </div>

              {/* Bill & Tender Displays */}
              <div className="grid grid-cols-2 gap-3">
                {/* Bill Amount */}
                <div className="p-3.5 bg-slate-950/80 border border-slate-800 rounded-2xl space-y-1">
                  <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">Total Bill Amount</span>
                  <div className="text-3xl font-mono font-black text-white">₹{billAmount.toFixed(2)}</div>
                </div>

                {/* Tender Received */}
                <div className="p-3.5 bg-slate-950/80 border border-slate-800 rounded-2xl space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">Cash Tender Received</span>
                    <button
                      type="button"
                      onClick={() => handleSetExactTender(billAmount)}
                      className="text-[10px] text-emerald-400 font-bold hover:underline cursor-pointer"
                    >
                      Exact (E)
                    </button>
                  </div>
                  <div className="flex items-center gap-1">
                    <span className="text-xl font-mono font-bold text-emerald-400">₹</span>
                    <input
                      type="number"
                      value={tenderReceived === 0 ? "" : tenderReceived}
                      onChange={(e) => setTenderReceived(Math.max(0, Number(e.target.value)))}
                      placeholder="0.00"
                      autoFocus
                      className="w-full bg-transparent text-3xl font-mono font-black text-emerald-300 focus:outline-none placeholder:text-slate-600"
                    />
                  </div>
                </div>
              </div>

              {/* Smart Note Suggestions (Phase 19.1) */}
              {paymentMode === "CASH" && (
                <div className="space-y-2">
                  <div className="flex items-center justify-between text-xs text-slate-400 font-semibold">
                    <span className="flex items-center gap-1 text-slate-300 font-bold">
                      <Sparkles className="w-3.5 h-3.5 text-amber-400" /> Smart Note Tenders:
                    </span>
                    <button
                      type="button"
                      onClick={() => setTenderReceived(0)}
                      className="flex items-center gap-1 text-[11px] text-slate-400 hover:text-rose-400 transition-colors cursor-pointer"
                    >
                      <RotateCcw className="w-3 h-3" />
                      <span>Reset</span>
                    </button>
                  </div>

                  <div className="grid grid-cols-4 sm:grid-cols-5 gap-2">
                    {smartTenderOptions.map((opt) => (
                      <button
                        key={opt.label}
                        type="button"
                        onClick={() => handleSetExactTender(opt.amount)}
                        className={`py-2 px-2 border rounded-xl text-center transition-all cursor-pointer hover:scale-102 active:scale-98 shadow-xs ${
                          tenderReceived === opt.amount
                            ? "bg-emerald-600/30 border-emerald-500 text-emerald-300 font-black ring-1 ring-emerald-500/50"
                            : "bg-slate-800/80 hover:bg-slate-700/80 border-slate-700 text-slate-200"
                        }`}
                      >
                        <span className="block text-xs font-mono font-bold">{opt.label}</span>
                        <span className="block text-[9px] text-slate-400 uppercase tracking-tight">{opt.hint}</span>
                      </button>
                    ))}
                  </div>

                  {/* Quick Add Chips */}
                  <div className="flex items-center gap-1.5 overflow-x-auto pt-1 pb-0.5 no-scrollbar">
                    <span className="text-[10px] text-slate-500 font-bold uppercase shrink-0">Add Note:</span>
                    {[10, 20, 50, 100, 200, 500].map((note) => (
                      <button
                        key={note}
                        type="button"
                        onClick={() => handleAddDenomination(note)}
                        className="px-2.5 py-1 bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded-lg text-[11px] font-mono font-semibold text-slate-300 transition-all shrink-0 cursor-pointer"
                      >
                        +₹{note}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* Cash Change Return Calculator Display (Phase 19.1) */}
              {paymentMode === "CASH" ? (
                <div
                  className={`p-4 rounded-2xl border transition-all ${
                    isShort
                      ? "bg-rose-950/60 border-rose-700/80 text-rose-200"
                      : "bg-gradient-to-br from-emerald-950/80 to-teal-950/60 border-emerald-700/80 text-emerald-200 shadow-inner"
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      {isShort ? (
                        <div className="p-2.5 bg-rose-900/60 rounded-xl border border-rose-700 text-rose-300 shrink-0">
                          <AlertCircle className="w-6 h-6 text-rose-400" />
                        </div>
                      ) : (
                        <div className="p-2.5 bg-emerald-900/60 rounded-xl border border-emerald-700 text-emerald-300 shrink-0">
                          <Coins className="w-6 h-6 text-emerald-400 animate-pulse" />
                        </div>
                      )}
                      <div>
                        <p className="text-xs font-bold uppercase tracking-wider">
                          {isShort ? "Shortfall / Cash Due from Customer" : "Change to Return to Customer"}
                        </p>
                        <p className="text-[11px] opacity-80">
                          {isShort
                            ? `Customer owes ₹${shortAmount.toFixed(2)} more to complete bill`
                            : "Count physical cash change notes before finalizing"}
                        </p>
                      </div>
                    </div>
                    <div className="text-right">
                      <span className="text-[10px] uppercase font-bold text-slate-400 block">
                        {isShort ? "Shortfall" : "Return Amount"}
                      </span>
                      <span className={`text-3xl font-mono font-black tracking-tight ${isShort ? "text-rose-400" : "text-emerald-300"}`}>
                        ₹{isShort ? shortAmount.toFixed(2) : changeReturned.toFixed(2)}
                      </span>
                    </div>
                  </div>

                  {/* Recommended Physical Currency Notes to Give (Phase 19.1) */}
                  {!isShort && changeReturned > 0 && changeNotesBreakdown.length > 0 && (
                    <div className="mt-3 pt-3 border-t border-emerald-800/60 flex items-center justify-between">
                      <span className="text-[11px] text-emerald-300/80 font-semibold flex items-center gap-1">
                        <ReceiptText className="w-3.5 h-3.5 text-emerald-400" /> Optimal Change Notes:
                      </span>
                      <div className="flex items-center gap-1.5 flex-wrap justify-end">
                        {changeNotesBreakdown.map((item) => (
                          <span
                            key={item.note}
                            className="px-2 py-0.5 bg-emerald-900/80 border border-emerald-600/70 rounded-md text-[10px] font-mono font-bold text-emerald-200"
                          >
                            ₹{item.note} × {item.count}
                          </span>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              ) : paymentMode === "UPI" ? (
                /* UPI Dynamic QR Mode */
                <div className="p-4 bg-teal-950/40 border border-teal-800/60 rounded-2xl flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="p-2.5 bg-teal-900/60 rounded-xl border border-teal-700 text-teal-300">
                      <QrCode className="w-6 h-6" />
                    </div>
                    <div>
                      <p className="text-xs font-bold text-teal-200">Customer Dynamic UPI QR</p>
                      <p className="text-[11px] text-teal-400/80">
                        Scan with Google Pay, PhonePe, Paytm or BHIM (Zero MDR)
                      </p>
                    </div>
                  </div>
                  <div className="text-2xl font-mono font-black text-teal-300">
                    ₹{billAmount.toFixed(2)}
                  </div>
                </div>
              ) : (
                /* Udhaar / Khata Mode */
                <div className="p-4 bg-amber-950/40 border border-amber-800/60 rounded-2xl flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="p-2.5 bg-amber-900/60 rounded-xl border border-amber-700 text-amber-300">
                      <BookOpen className="w-6 h-6" />
                    </div>
                    <div>
                      <p className="text-xs font-bold text-amber-200">Khata (Customer Credit Ledger)</p>
                      <p className="text-[11px] text-amber-400/80">
                        Will be debited to attached customer account automatically
                      </p>
                    </div>
                  </div>
                  <div className="text-2xl font-mono font-black text-amber-300">
                    ₹{billAmount.toFixed(2)}
                  </div>
                </div>
              )}

              {/* Action Buttons & Shortcut Keys */}
              <div className="flex items-center gap-2 pt-2">
                <button
                  type="button"
                  onClick={onClose}
                  className="w-1/3 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-bold rounded-xl transition-colors cursor-pointer"
                >
                  Cancel (Esc)
                </button>
                <button
                  type="button"
                  onClick={handleFinalize}
                  disabled={isShort && paymentMode === "CASH"}
                  className="w-2/3 py-2.5 bg-gradient-to-r from-emerald-600 via-teal-600 to-emerald-500 hover:from-emerald-500 hover:to-teal-500 disabled:opacity-50 text-white text-xs font-black rounded-xl shadow-lg shadow-emerald-950/80 flex items-center justify-center gap-2 cursor-pointer transition-all"
                >
                  <Printer className="w-4 h-4" />
                  <span>Confirm &amp; Finalize Bill</span>
                  <kbd className="px-1.5 py-0.2 rounded text-[10px] font-mono font-bold bg-white/20 text-white">
                    Enter
                  </kbd>
                  <ArrowRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          )}
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
