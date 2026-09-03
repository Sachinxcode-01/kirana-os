"use client";

import React, { useState, useEffect } from "react";
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
  Calculator,
  RotateCcw,
} from "lucide-react";

import { posAudio } from "@/utils/audioFeedback";

interface QuickTenderModalProps {
  isOpen: boolean;
  onClose: () => void;
  defaultBillAmount?: number; // In Rupees
  onSuccess?: (details: { billAmount: number; tenderReceived: number; changeReturned: number; mode: string }) => void;
  onTenderSuccess?: (mode: "CASH" | "UPI" | "UDHAAR") => void;
}

export function QuickTenderModal({
  isOpen,
  onClose,
  defaultBillAmount = 340,
  onSuccess,
  onTenderSuccess,
}: QuickTenderModalProps) {
  const [billAmount, setBillAmount] = useState<number>(defaultBillAmount);
  const [tenderReceived, setTenderReceived] = useState<number>(defaultBillAmount);
  const [paymentMode, setPaymentMode] = useState<"CASH" | "UPI">("CASH");
  const [isCompleted, setIsCompleted] = useState(false);

  useEffect(() => {
    if (isOpen) {
      setBillAmount(defaultBillAmount);
      setTenderReceived(defaultBillAmount);
      setIsCompleted(false);
    }
  }, [isOpen, defaultBillAmount]);

  if (!isOpen) return null;

  const changeReturned = Math.max(0, tenderReceived - billAmount);
  const isShort = tenderReceived < billAmount;
  const shortAmount = Math.max(0, billAmount - tenderReceived);

  const quickDenominations = [50, 100, 200, 500, 2000];

  const handleAddDenomination = (value: number) => {
    posAudio.playBarcodeBeep();
    setTenderReceived((prev) => prev + value);
  };

  const handleExactCash = () => {
    posAudio.playBarcodeBeep();
    setTenderReceived(billAmount);
  };

  const handleFinalize = () => {
    if (isShort && paymentMode === "CASH") {
      posAudio.playWarningBuzzer();
      return;
    }

    posAudio.playSuccessChime();
    setIsCompleted(true);
    setTimeout(() => {
      onSuccess?.({
        billAmount,
        tenderReceived,
        changeReturned,
        mode: paymentMode,
      });
      onTenderSuccess?.(paymentMode);
      setIsCompleted(false);
      onClose();
    }, 1200);
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
          className="absolute inset-0 bg-slate-950/70 backdrop-blur-sm cursor-pointer"
        />

        {/* Modal Window */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 15 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 15 }}
          transition={{ duration: 0.25, ease: "easeOut" }}
          className="relative w-full max-w-lg bg-slate-900 border border-slate-700/80 rounded-3xl shadow-2xl overflow-hidden z-10 text-slate-100"
        >
          {/* Ambient Glow */}
          <div className="absolute top-0 right-1/4 w-60 h-28 bg-emerald-500/15 rounded-full blur-3xl pointer-events-none" />

          {/* Modal Header */}
          <div className="flex items-center justify-between p-5 border-b border-slate-800 relative z-10">
            <div className="flex items-center gap-3">
              <div className="p-2.5 bg-gradient-to-br from-emerald-600 to-teal-600 rounded-2xl shadow-md shadow-emerald-950/50 border border-emerald-400/30">
                <Banknote className="w-5 h-5 text-white" />
              </div>
              <div>
                <h2 className="text-base font-black text-white flex items-center gap-2">
                  <span>Quick Cash Tender Calculator</span>
                  <kbd className="px-1.5 py-0.5 text-[10px] font-mono font-bold rounded bg-slate-800 text-emerald-300 border border-slate-700">
                    F4
                  </kbd>
                </h2>
                <p className="text-xs text-slate-400">One-tap denomination chips and instant change return</p>
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
              className="p-8 text-center space-y-3"
            >
              <div className="w-14 h-14 mx-auto bg-emerald-500/20 border border-emerald-500/40 rounded-full flex items-center justify-center text-emerald-400">
                <CheckCircle2 className="w-8 h-8 animate-bounce" />
              </div>
              <h3 className="text-lg font-black text-white">Bill Finalized &amp; Cash Recorded!</h3>
              <p className="text-xs text-slate-300">
                ₹{billAmount.toFixed(2)} received via {paymentMode}. Printing ESC/POS receipt...
              </p>
            </motion.div>
          ) : (
            /* Main Form */
            <div className="p-6 space-y-5">
              {/* Payment Mode Toggle Tabs */}
              <div className="grid grid-cols-2 gap-1.5 p-1 bg-slate-950/90 rounded-2xl border border-slate-800">
                <button
                  type="button"
                  onClick={() => setPaymentMode("CASH")}
                  className={`py-2 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-2 cursor-pointer ${
                    paymentMode === "CASH"
                      ? "bg-gradient-to-r from-emerald-600 to-teal-600 text-white shadow-md shadow-emerald-950/60"
                      : "text-slate-400 hover:text-slate-200"
                  }`}
                >
                  <Banknote className="w-4 h-4" />
                  <span>Cash Tender</span>
                </button>
                <button
                  type="button"
                  onClick={() => setPaymentMode("UPI")}
                  className={`py-2 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-2 cursor-pointer ${
                    paymentMode === "UPI"
                      ? "bg-gradient-to-r from-teal-600 to-cyan-600 text-white shadow-md shadow-teal-950/60"
                      : "text-slate-400 hover:text-slate-200"
                  }`}
                >
                  <QrCode className="w-4 h-4" />
                  <span>UPI Dynamic QR</span>
                </button>
              </div>

              {/* Bill & Tender Displays */}
              <div className="grid grid-cols-2 gap-3">
                {/* Bill Amount */}
                <div className="p-3.5 bg-slate-950/80 border border-slate-800 rounded-2xl space-y-1">
                  <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">Bill Total</span>
                  <div className="text-2xl font-mono font-black text-white">₹{billAmount.toFixed(2)}</div>
                </div>

                {/* Tender Received */}
                <div className="p-3.5 bg-slate-950/80 border border-slate-800 rounded-2xl space-y-1">
                  <div className="flex items-center justify-between">
                    <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">Tender Received</span>
                    <button
                      onClick={handleExactCash}
                      className="text-[10px] text-emerald-400 font-bold hover:underline cursor-pointer"
                    >
                      Exact (₹{billAmount})
                    </button>
                  </div>
                  <div className="flex items-center gap-1">
                    <span className="text-lg font-mono font-bold text-emerald-400">₹</span>
                    <input
                      type="number"
                      value={tenderReceived}
                      onChange={(e) => setTenderReceived(Math.max(0, Number(e.target.value)))}
                      className="w-full bg-transparent text-2xl font-mono font-black text-emerald-300 focus:outline-none"
                    />
                  </div>
                </div>
              </div>

              {/* Dynamic Denomination Click Chips (Cash Mode) */}
              {paymentMode === "CASH" && (
                <div className="space-y-2">
                  <div className="flex items-center justify-between text-xs text-slate-400 font-bold">
                    <span>Quick Denomination Chips:</span>
                    <button
                      onClick={() => setTenderReceived(0)}
                      className="flex items-center gap-1 text-[11px] text-slate-400 hover:text-rose-400 transition-colors cursor-pointer"
                    >
                      <RotateCcw className="w-3 h-3" />
                      <span>Reset</span>
                    </button>
                  </div>

                  <div className="grid grid-cols-5 gap-2">
                    {quickDenominations.map((note) => (
                      <button
                        key={note}
                        type="button"
                        onClick={() => handleAddDenomination(note)}
                        className="py-2.5 px-2 bg-slate-800/90 hover:bg-slate-700/90 border border-slate-700 rounded-xl text-center transition-all cursor-pointer hover:scale-103 active:scale-97 shadow-xs"
                      >
                        <span className="block text-xs font-mono font-black text-slate-200">+₹{note}</span>
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* Dynamic Change Return Card */}
              {paymentMode === "CASH" ? (
                <div
                  className={`p-4 rounded-2xl border transition-all ${
                    isShort
                      ? "bg-rose-950/50 border-rose-800/70 text-rose-300"
                      : "bg-emerald-950/50 border-emerald-800/70 text-emerald-300"
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      {isShort ? (
                        <AlertCircle className="w-5 h-5 text-rose-400 shrink-0" />
                      ) : (
                        <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0" />
                      )}
                      <div>
                        <p className="text-xs font-bold uppercase tracking-wider">
                          {isShort ? "Insufficient Cash Tendered" : "Change to Return to Customer"}
                        </p>
                        <p className="text-[11px] opacity-80">
                          {isShort
                            ? `Customer owes ₹${shortAmount.toFixed(2)} more`
                            : "Hand over physical change before finalizing"}
                        </p>
                      </div>
                    </div>
                    <div className="text-2xl font-mono font-black">
                      ₹{isShort ? shortAmount.toFixed(2) : changeReturned.toFixed(2)}
                    </div>
                  </div>
                </div>
              ) : (
                /* UPI Payment Box */
                <div className="p-4 bg-teal-950/40 border border-teal-800/60 rounded-2xl flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="p-2.5 bg-teal-900/60 rounded-xl border border-teal-700 text-teal-300">
                      <QrCode className="w-6 h-6" />
                    </div>
                    <div>
                      <p className="text-xs font-bold text-teal-200">Customer Dynamic UPI QR</p>
                      <p className="text-[11px] text-teal-400/80">
                        Scan with Google Pay, PhonePe, Paytm or BHIM
                      </p>
                    </div>
                  </div>
                  <div className="text-xl font-mono font-black text-teal-300">
                    ₹{billAmount.toFixed(2)}
                  </div>
                </div>
              )}

              {/* Action Buttons */}
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
                  <span>Confirm &amp; Finalize Bill (F12)</span>
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
