"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  FileSpreadsheet,
  X,
  Printer,
  Download,
  CheckCircle2,
  AlertTriangle,
  Banknote,
  QrCode,
  Users,
  Coins,
  ShieldCheck,
  RotateCcw,
} from "lucide-react";
import { posAudio } from "@/utils/audioFeedback";
import { useLanguage } from "@/contexts/LanguageContext";

interface DayEndZReportModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function DayEndZReportModal({ isOpen, onClose }: DayEndZReportModalProps) {
  const { t } = useLanguage();

  // Audit Metrics (Paise converted to Rupees for display)
  const openingFloat = 2000;
  const cashSales = 7595;
  const supplierPayouts = 1200;
  const expectedCash = openingFloat + cashSales - supplierPayouts; // 8395

  const upiSales = 13230;
  const udhaarSales = 3675;
  const grossRevenue = cashSales + upiSales + udhaarSales; // 24500
  const totalBillsCount = 42;

  const [actualCashCounted, setActualCashCounted] = useState<number>(expectedCash);
  const [isShiftClosed, setIsShiftClosed] = useState(false);

  if (!isOpen) return null;

  const discrepancy = actualCashCounted - expectedCash;
  const isBalanced = discrepancy === 0;
  const isOver = discrepancy > 0;
  const isShort = discrepancy < 0;

  const handlePrintZReport = () => {
    posAudio.playSuccessChime();
    window.print();
  };

  const handleExportCsv = () => {
    posAudio.playBarcodeBeep();
    const headers = "Metric,Amount (INR)\n";
    const rows = [
      `Shift Date,${new Date().toLocaleDateString("en-IN")}`,
      `Counter,Register POS-01`,
      `Cashier,Ramesh Kumar (Owner)`,
      `Total Gross Revenue,${grossRevenue.toFixed(2)}`,
      `Opening Cash Float,${openingFloat.toFixed(2)}`,
      `Cash Sales,${cashSales.toFixed(2)}`,
      `Supplier Cash Payouts,-${supplierPayouts.toFixed(2)}`,
      `Expected Cash Drawer,${expectedCash.toFixed(2)}`,
      `Actual Cash Counted,${actualCashCounted.toFixed(2)}`,
      `Cash Discrepancy,${discrepancy.toFixed(2)}`,
      `UPI Digital Collections,${upiSales.toFixed(2)}`,
      `Pending Udhaar Debts,${udhaarSales.toFixed(2)}`,
      `Total Bills Finalized,${totalBillsCount}`,
    ].join("\n");

    const blob = new Blob([headers + rows], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `Z-REPORT-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleCloseShift = () => {
    posAudio.playSuccessChime();
    setIsShiftClosed(true);
    setTimeout(() => {
      setIsShiftClosed(false);
      onClose();
    }, 1500);
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
          className="absolute inset-0 bg-slate-950/75 backdrop-blur-sm cursor-pointer"
        />

        {/* Modal Window */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 15 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 15 }}
          transition={{ duration: 0.25, ease: "easeOut" }}
          className="relative w-full max-w-2xl bg-slate-900 border border-slate-700/80 rounded-3xl shadow-2xl overflow-hidden z-10 text-slate-100 flex flex-col max-h-[92vh]"
        >
          {/* Ambient Glow */}
          <div className="absolute top-0 right-1/3 w-80 h-28 bg-emerald-500/15 rounded-full blur-3xl pointer-events-none" />

          {/* Modal Header */}
          <div className="flex items-center justify-between p-5 border-b border-slate-800 relative z-10">
            <div className="flex items-center gap-3">
              <div className="p-2.5 bg-gradient-to-br from-teal-600 to-emerald-600 rounded-2xl shadow-md shadow-emerald-950/50 border border-emerald-400/30">
                <FileSpreadsheet className="w-5 h-5 text-white" />
              </div>
              <div>
                <h2 className="text-base font-black text-white flex items-center gap-2">
                  <span>Day-End Z-Report Reconciliation</span>
                  <span className="text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-300 border border-emerald-500/40">
                    Shift 01
                  </span>
                </h2>
                <p className="text-xs text-slate-400">
                  Cash drawer balancing, digital collections, and supplier payout audit
                </p>
              </div>
            </div>

            <button
              onClick={onClose}
              className="p-2 text-slate-400 hover:text-white rounded-xl hover:bg-slate-800 transition-colors cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Body Content */}
          <div className="p-6 space-y-5 overflow-y-auto">
            {isShiftClosed ? (
              <motion.div
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                className="py-10 text-center space-y-3"
              >
                <div className="w-16 h-16 mx-auto bg-emerald-500/20 border border-emerald-500/40 rounded-full flex items-center justify-center text-emerald-400">
                  <CheckCircle2 className="w-9 h-9 animate-bounce" />
                </div>
                <h3 className="text-xl font-black text-white">Shift Successfully Closed!</h3>
                <p className="text-xs text-slate-300 max-w-sm mx-auto">
                  Z-Report finalized and archived in cloud storage. Cash drawer locked for next shift.
                </p>
              </motion.div>
            ) : (
              <>
                {/* 1. Cash Drawer Float & Sales Mathematical Reconciliation */}
                <div className="p-4 bg-slate-950/80 rounded-2xl border border-slate-800 space-y-3">
                  <div className="flex items-center justify-between text-xs font-bold text-slate-300">
                    <span className="flex items-center gap-1.5 uppercase tracking-wider text-emerald-400">
                      <Banknote className="w-4 h-4" /> Physical Cash Drawer Audit
                    </span>
                    <button
                      type="button"
                      onClick={() => setActualCashCounted(expectedCash)}
                      className="text-[11px] text-emerald-400 hover:underline flex items-center gap-1 cursor-pointer"
                    >
                      <RotateCcw className="w-3 h-3" /> Auto-Match Expected
                    </button>
                  </div>

                  <div className="grid grid-cols-3 gap-2.5 text-xs text-slate-400 font-mono">
                    <div className="p-2.5 bg-slate-900 rounded-xl border border-slate-800">
                      <p className="text-[10px] text-slate-500 uppercase">Opening Float</p>
                      <p className="text-sm font-black text-white mt-1">₹{openingFloat.toFixed(2)}</p>
                    </div>
                    <div className="p-2.5 bg-slate-900 rounded-xl border border-slate-800">
                      <p className="text-[10px] text-emerald-500 uppercase">+ Cash Sales</p>
                      <p className="text-sm font-black text-emerald-300 mt-1">₹{cashSales.toFixed(2)}</p>
                    </div>
                    <div className="p-2.5 bg-slate-900 rounded-xl border border-slate-800">
                      <p className="text-[10px] text-rose-400 uppercase">- Payouts</p>
                      <p className="text-sm font-black text-rose-300 mt-1">₹{supplierPayouts.toFixed(2)}</p>
                    </div>
                  </div>

                  {/* Expected vs Actual Counted Row */}
                  <div className="grid grid-cols-2 gap-3 pt-2">
                    <div className="p-3 bg-slate-900/90 rounded-xl border border-slate-800 space-y-1">
                      <span className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">
                        Expected Drawer Cash
                      </span>
                      <div className="text-xl font-mono font-black text-white">₹{expectedCash.toFixed(2)}</div>
                    </div>

                    <div className="p-3 bg-slate-900/90 rounded-xl border border-slate-800 space-y-1">
                      <span className="text-[10px] text-slate-400 uppercase font-bold tracking-wider">
                        Actual Physical Cash Counted
                      </span>
                      <div className="flex items-center gap-1">
                        <span className="text-lg font-mono font-bold text-emerald-400">₹</span>
                        <input
                          type="number"
                          value={actualCashCounted}
                          onChange={(e) => setActualCashCounted(Number(e.target.value))}
                          className="w-full bg-transparent text-xl font-mono font-black text-emerald-300 focus:outline-none"
                        />
                      </div>
                    </div>
                  </div>

                  {/* Discrepancy Indicator Banner */}
                  <div
                    className={`p-3 rounded-xl border flex items-center justify-between text-xs font-bold ${
                      isBalanced
                        ? "bg-emerald-950/60 border-emerald-800 text-emerald-300"
                        : isOver
                        ? "bg-amber-950/60 border-amber-800 text-amber-300"
                        : "bg-rose-950/60 border-rose-800 text-rose-300"
                    }`}
                  >
                    <div className="flex items-center gap-2">
                      {isBalanced ? (
                        <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                      ) : (
                        <AlertTriangle className="w-4 h-4 text-amber-400" />
                      )}
                      <span>
                        {isBalanced
                          ? "Cash Drawer Exactly Balanced: ₹0.00 Variance"
                          : isOver
                          ? `Drawer is OVER by +₹${discrepancy.toFixed(2)} (Excess Cash)`
                          : `Drawer is SHORT by -₹${Math.abs(discrepancy).toFixed(2)} (Missing Cash)`}
                      </span>
                    </div>
                    <span className="font-mono text-sm font-black">
                      {isOver ? `+₹${discrepancy.toFixed(2)}` : isShort ? `-₹${Math.abs(discrepancy).toFixed(2)}` : "₹0.00"}
                    </span>
                  </div>
                </div>

                {/* 2. Total Daily Revenue Breakdown */}
                <div className="grid grid-cols-3 gap-3">
                  <div className="p-3 bg-slate-950/70 rounded-2xl border border-slate-800 space-y-1">
                    <div className="flex items-center gap-1 text-[11px] font-bold text-teal-400 uppercase">
                      <QrCode className="w-3.5 h-3.5" /> UPI Settlements
                    </div>
                    <div className="text-base font-mono font-black text-white">₹{upiSales.toFixed(2)}</div>
                    <p className="text-[10px] text-slate-500">Auto-credited to bank</p>
                  </div>

                  <div className="p-3 bg-slate-950/70 rounded-2xl border border-slate-800 space-y-1">
                    <div className="flex items-center gap-1 text-[11px] font-bold text-amber-400 uppercase">
                      <Users className="w-3.5 h-3.5" /> Credit Khata
                    </div>
                    <div className="text-base font-mono font-black text-white">₹{udhaarSales.toFixed(2)}</div>
                    <p className="text-[10px] text-slate-500">Booked to customer accounts</p>
                  </div>

                  <div className="p-3 bg-slate-950/70 rounded-2xl border border-slate-800 space-y-1">
                    <div className="flex items-center gap-1 text-[11px] font-bold text-emerald-400 uppercase">
                      <ShieldCheck className="w-3.5 h-3.5" /> Total Gross Sales
                    </div>
                    <div className="text-base font-mono font-black text-emerald-300">₹{grossRevenue.toFixed(2)}</div>
                    <p className="text-[10px] text-slate-500">{totalBillsCount} total customer bills</p>
                  </div>
                </div>
              </>
            )}
          </div>

          {/* Footer Controls */}
          {!isShiftClosed && (
            <div className="p-4 border-t border-slate-800 bg-slate-900/90 flex items-center justify-between gap-3">
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={handleExportCsv}
                  className="px-3.5 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer"
                >
                  <Download className="w-3.5 h-3.5" />
                  <span>Export CSV</span>
                </button>

                <button
                  type="button"
                  onClick={handlePrintZReport}
                  className="px-3.5 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer"
                >
                  <Printer className="w-3.5 h-3.5" />
                  <span>Print Z-Report</span>
                </button>
              </div>

              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={onClose}
                  className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-bold transition-all cursor-pointer"
                >
                  Cancel
                </button>

                <button
                  type="button"
                  onClick={handleCloseShift}
                  className="px-5 py-2 bg-gradient-to-r from-emerald-600 via-teal-600 to-emerald-500 hover:from-emerald-500 hover:to-teal-500 text-white rounded-xl text-xs font-black shadow-lg shadow-emerald-950/60 flex items-center gap-1.5 cursor-pointer transition-all"
                >
                  <CheckCircle2 className="w-4 h-4" />
                  <span>Confirm &amp; Close Shift</span>
                </button>
              </div>
            </div>
          )}
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
