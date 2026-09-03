"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  X,
  Building2,
  Phone,
  MessageSquare,
  Truck,
  PackageCheck,
  CreditCard,
  FileText,
  Boxes,
  CheckCircle2,
  Calendar,
} from "lucide-react";
import { WebSupplier } from "@/types";
import { formatPaise } from "@/utils/currency";
import { posAudio } from "@/utils/audioFeedback";

interface Supplier360DrawerProps {
  supplier: WebSupplier | null;
  isOpen: boolean;
  onClose: () => void;
  onRecordPayment?: (supplier: WebSupplier) => void;
}

export function Supplier360Drawer({
  supplier,
  isOpen,
  onClose,
  onRecordPayment,
}: Supplier360DrawerProps) {
  const [activeTab, setActiveTab] = useState<"inward" | "crates">("inward");

  if (!isOpen || !supplier) return null;

  const handleWhatsAppInquiry = () => {
    posAudio.playBarcodeBeep();
    const cleanPhone = supplier.phone.replace(/\D/g, "");
    const text = `Namaste ${supplier.contactPerson} ji,\n\nRegarding *${supplier.name}* account at Kirana Store. Please send the latest delivery statement and stock catalog.\n\nThank you!`;
    const url = `https://wa.me/91${cleanPhone}?text=${encodeURIComponent(text)}`;
    window.open(url, "_blank");
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 overflow-hidden">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
          className="absolute inset-0 bg-slate-950/60 backdrop-blur-xs cursor-pointer"
        />

        {/* Slide-Over Drawer */}
        <motion.div
          initial={{ x: "100%" }}
          animate={{ x: 0 }}
          exit={{ x: "100%" }}
          transition={{ type: "spring", damping: 30, stiffness: 300 }}
          className="absolute inset-y-0 right-0 max-w-xl w-full bg-slate-900 border-l border-slate-800 shadow-2xl flex flex-col text-slate-100 z-10"
        >
          {/* Drawer Header */}
          <div className="p-5 border-b border-slate-800 bg-slate-950/80 flex items-start justify-between gap-4">
            <div className="flex items-center gap-3.5">
              <div className="w-13 h-13 rounded-2xl bg-gradient-to-tr from-cyan-600 to-blue-600 flex items-center justify-center text-white font-black text-lg shadow-lg shadow-cyan-950/50 border border-cyan-400/30">
                <Truck className="w-6 h-6 text-white" />
              </div>
              <div>
                <h2 className="text-base font-black text-white">{supplier.name}</h2>
                <p className="text-xs text-slate-400 flex items-center gap-1.5 mt-0.5">
                  <span>Contact: {supplier.contactPerson}</span>
                  <span>•</span>
                  <span className="font-mono">+91 {supplier.phone}</span>
                </p>
                {supplier.gstin && (
                  <p className="text-[10px] text-slate-500 font-mono mt-0.5">
                    GSTIN: {supplier.gstin}
                  </p>
                )}
              </div>
            </div>

            <button
              onClick={onClose}
              className="p-2 text-slate-400 hover:text-white rounded-xl hover:bg-slate-800 transition-colors cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Quick Metrics Bar */}
          <div className="grid grid-cols-2 gap-3 p-4 bg-slate-950/50 border-b border-slate-800/80 text-center">
            <div className="p-3 rounded-xl bg-slate-900/90 border border-slate-800">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
                Outstanding Payable Dues
              </span>
              <span className="text-lg font-mono font-black text-rose-400">
                {formatPaise(supplier.pendingBalancePaise)}
              </span>
            </div>

            <div className="p-3 rounded-xl bg-slate-900/90 border border-slate-800">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
                Credit Status
              </span>
              <span className="text-sm font-bold text-emerald-400 flex items-center justify-center gap-1 mt-1">
                <CheckCircle2 className="w-4 h-4" /> Active 15-Day Net
              </span>
            </div>
          </div>

          {/* 2 Tabs */}
          <div className="flex border-b border-slate-800 bg-slate-950/30 px-4 pt-2 gap-2 shrink-0">
            <button
              type="button"
              onClick={() => setActiveTab("inward")}
              className={`pb-2.5 px-3 text-xs font-bold transition-all border-b-2 cursor-pointer flex items-center gap-1.5 ${
                activeTab === "inward"
                  ? "border-cyan-500 text-cyan-400"
                  : "border-transparent text-slate-400 hover:text-slate-200"
              }`}
            >
              <FileText className="w-4 h-4" />
              <span>Inward Delivery Bills</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveTab("crates")}
              className={`pb-2.5 px-3 text-xs font-bold transition-all border-b-2 cursor-pointer flex items-center gap-1.5 ${
                activeTab === "crates"
                  ? "border-cyan-500 text-cyan-400"
                  : "border-transparent text-slate-400 hover:text-slate-200"
              }`}
            >
              <Boxes className="w-4 h-4" />
              <span>Crates Owed to Distributor (8)</span>
            </button>
          </div>

          {/* Drawer Body */}
          <div className="flex-1 overflow-y-auto p-5 space-y-4">
            {activeTab === "inward" && (
              <div className="space-y-3">
                <div className="p-3.5 bg-slate-950/80 border border-slate-800 rounded-2xl flex items-center justify-between">
                  <div>
                    <h4 className="text-xs font-bold text-white">Stock Inward Batch #PO-2026-0042</h4>
                    <p className="text-[11px] text-slate-400 font-mono">
                      14 SKUs received • 01 Sep 2026 • Verified
                    </p>
                  </div>
                  <div className="text-right">
                    <span className="text-xs font-mono font-black text-white block">₹28,500.00</span>
                    <span className="text-[10px] text-emerald-400 font-bold">Paid via RTGS</span>
                  </div>
                </div>

                <div className="p-3.5 bg-slate-950/80 border border-slate-800 rounded-2xl flex items-center justify-between">
                  <div>
                    <h4 className="text-xs font-bold text-white">Stock Inward Batch #PO-2026-0038</h4>
                    <p className="text-[11px] text-slate-400 font-mono">
                      22 SKUs received • 24 Aug 2026 • Verified
                    </p>
                  </div>
                  <div className="text-right">
                    <span className="text-xs font-mono font-black text-rose-400 block">₹45,000.00</span>
                    <span className="text-[10px] text-amber-400 font-bold">Credit Pending</span>
                  </div>
                </div>
              </div>
            )}

            {activeTab === "crates" && (
              <div className="space-y-3">
                <div className="p-3.5 bg-slate-950/80 border border-slate-800 rounded-2xl">
                  <h4 className="text-xs font-bold text-white">Empty Cases Due for Return</h4>
                  <p className="text-[11px] text-slate-400 mt-0.5">
                    Physical transport packaging that must be returned to distributor driver upon next delivery.
                  </p>
                </div>

                <div className="p-3 bg-slate-950/80 border border-slate-800 rounded-2xl flex items-center justify-between">
                  <div>
                    <h5 className="text-xs font-bold text-slate-200">Heavy Duty Dairy Plastic Crates</h5>
                    <p className="text-[11px] text-slate-400">Holds 12 x 500ml packets</p>
                  </div>
                  <span className="px-2.5 py-1 bg-cyan-950 text-cyan-300 border border-cyan-800 rounded-lg text-xs font-mono font-bold">
                    6 Crates Due
                  </span>
                </div>

                <div className="p-3 bg-slate-950/80 border border-slate-800 rounded-2xl flex items-center justify-between">
                  <div>
                    <h5 className="text-xs font-bold text-slate-200">Glass Bottle Wooden Shells</h5>
                    <p className="text-[11px] text-slate-400">Holds 24 x 200ml bottles</p>
                  </div>
                  <span className="px-2.5 py-1 bg-cyan-950 text-cyan-300 border border-cyan-800 rounded-lg text-xs font-mono font-bold">
                    2 Cases Due
                  </span>
                </div>
              </div>
            )}
          </div>

          {/* Action Footer */}
          <div className="p-4 border-t border-slate-800 bg-slate-950/90 flex items-center gap-2">
            <button
              type="button"
              onClick={handleWhatsAppInquiry}
              className="w-1/2 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold rounded-xl flex items-center justify-center gap-2 transition-colors cursor-pointer"
            >
              <MessageSquare className="w-4 h-4 text-emerald-400" />
              <span>WhatsApp Inquiry</span>
            </button>

            <button
              type="button"
              onClick={() => {
                onRecordPayment?.(supplier);
                onClose();
              }}
              className="w-1/2 py-2.5 bg-gradient-to-r from-cyan-600 to-blue-600 hover:from-cyan-500 hover:to-blue-500 text-white text-xs font-black rounded-xl shadow-lg shadow-cyan-950/60 flex items-center justify-center gap-2 transition-all cursor-pointer"
            >
              <CreditCard className="w-4 h-4" />
              <span>Record Payment</span>
            </button>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
