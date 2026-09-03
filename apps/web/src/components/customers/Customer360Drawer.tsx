"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  X,
  Phone,
  MessageSquare,
  Sparkles,
  Receipt,
  RotateCcw,
  CheckCircle2,
  AlertTriangle,
  Package,
  Calendar,
  CreditCard,
  Printer,
  ChevronRight,
  TrendingUp,
  Boxes,
} from "lucide-react";
import { WebCustomer } from "@/types";
import { formatPaise } from "@/utils/currency";
import { posAudio } from "@/utils/audioFeedback";

interface Customer360DrawerProps {
  customer: WebCustomer | null;
  isOpen: boolean;
  onClose: () => void;
  onRecordPayment?: (customer: WebCustomer) => void;
}

interface ReturnableContainer {
  id: string;
  name: string;
  count: number;
  depositPerUnitPaise: number;
  lastUpdated: string;
}

export function Customer360Drawer({
  customer,
  isOpen,
  onClose,
  onRecordPayment,
}: Customer360DrawerProps) {
  const [activeTab, setActiveTab] = useState<"ledger" | "crates" | "loyalty">("ledger");

  // Sample returnable containers tracked for this customer
  const [containers, setContainers] = useState<ReturnableContainer[]>([
    { id: "cnt-1", name: "20L Mineral Water Jar", count: 1, depositPerUnitPaise: 15000, lastUpdated: "Yesterday" },
    { id: "cnt-2", name: "Amul Milk 12-Pkt Plastic Crate", count: 2, depositPerUnitPaise: 10000, lastUpdated: "3 days ago" },
    { id: "cnt-3", name: "Glass Soda Bottles (200ml)", count: 6, depositPerUnitPaise: 1000, lastUpdated: "Last week" },
  ]);

  if (!isOpen || !customer) return null;

  const totalDepositPaise = containers.reduce((acc, c) => acc + c.count * c.depositPerUnitPaise, 0);
  const creditUsagePercent = customer.creditLimitPaise > 0
    ? Math.min(100, Math.round((customer.currentBalancePaise / customer.creditLimitPaise) * 100))
    : 0;

  const handleReturnContainer = (id: string) => {
    posAudio.playBarcodeBeep();
    setContainers((prev) =>
      prev.map((c) => (c.id === id ? { ...c, count: Math.max(0, c.count - 1) } : c))
    );
  };

  const handleSendWhatsAppReminder = () => {
    posAudio.playBarcodeBeep();
    const cleanPhone = customer.phone.replace(/\D/g, "");
    const dueRupees = (customer.currentBalancePaise / 100).toFixed(2);
    const storeName = "Kirana Store";
    const upiDeepLink = `upi://pay?pa=kirana@upi&pn=${encodeURIComponent(storeName)}&am=${dueRupees}&cu=INR`;

    const text = `Namaste ${customer.name} ji,\n\nYour outstanding khata balance at *${storeName}* is *₹${dueRupees}*.\n\nYou can clear your balance via UPI:\n${upiDeepLink}\n\nThank you for shopping with us! 🙏`;
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
              <div className="w-13 h-13 rounded-2xl bg-gradient-to-tr from-emerald-600 to-teal-500 flex items-center justify-center text-white font-black text-lg shadow-lg shadow-emerald-950/50 border border-emerald-400/30">
                {customer.name.slice(0, 2).toUpperCase()}
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <h2 className="text-base font-black text-white">{customer.name}</h2>
                  <span
                    className={`px-2 py-0.5 rounded-full text-[10px] font-mono font-bold border ${
                      customer.currentBalancePaise === 0
                        ? "bg-emerald-950/80 text-emerald-300 border-emerald-800/80"
                        : creditUsagePercent >= 80
                        ? "bg-rose-950/80 text-rose-300 border-rose-800/80"
                        : "bg-amber-950/80 text-amber-300 border-amber-800/80"
                    }`}
                  >
                    {customer.currentBalancePaise === 0
                      ? "Zero Debt"
                      : `${creditUsagePercent}% Credit Used`}
                  </span>
                </div>
                <p className="text-xs text-slate-400 flex items-center gap-1.5 mt-0.5">
                  <Phone className="w-3 h-3 text-emerald-400" />
                  <span className="font-mono">+91 {customer.phone}</span>
                  {customer.address && (
                    <>
                      <span>•</span>
                      <span className="truncate max-w-[200px]">{customer.address}</span>
                    </>
                  )}
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

          {/* Quick Metrics Bar */}
          <div className="grid grid-cols-3 gap-2 p-4 bg-slate-950/50 border-b border-slate-800/80 text-center">
            <div className="p-2.5 rounded-xl bg-slate-900/90 border border-slate-800">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
                Khata Balance
              </span>
              <span className="text-sm sm:text-base font-mono font-black text-amber-400">
                {formatPaise(customer.currentBalancePaise)}
              </span>
            </div>

            <div className="p-2.5 rounded-xl bg-slate-900/90 border border-slate-800">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
                Credit Limit
              </span>
              <span className="text-sm sm:text-base font-mono font-black text-slate-200">
                {formatPaise(customer.creditLimitPaise)}
              </span>
            </div>

            <div className="p-2.5 rounded-xl bg-slate-900/90 border border-slate-800">
              <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">
                Loyalty Points
              </span>
              <span className="text-sm sm:text-base font-mono font-black text-teal-400 flex items-center justify-center gap-1">
                <Sparkles className="w-3.5 h-3.5" />
                {customer.loyaltyPoints} pts
              </span>
            </div>
          </div>

          {/* 3-Way Navigation Tabs */}
          <div className="flex border-b border-slate-800 bg-slate-950/30 px-4 pt-2 gap-2 shrink-0">
            <button
              type="button"
              onClick={() => setActiveTab("ledger")}
              className={`pb-2.5 px-3 text-xs font-bold transition-all border-b-2 cursor-pointer flex items-center gap-1.5 ${
                activeTab === "ledger"
                  ? "border-emerald-500 text-emerald-400"
                  : "border-transparent text-slate-400 hover:text-slate-200"
              }`}
            >
              <Receipt className="w-4 h-4" />
              <span>Khata Ledger</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveTab("crates")}
              className={`pb-2.5 px-3 text-xs font-bold transition-all border-b-2 cursor-pointer flex items-center gap-1.5 ${
                activeTab === "crates"
                  ? "border-emerald-500 text-emerald-400"
                  : "border-transparent text-slate-400 hover:text-slate-200"
              }`}
            >
              <Boxes className="w-4 h-4" />
              <span>Crates &amp; Empties ({containers.reduce((a, b) => a + b.count, 0)})</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveTab("loyalty")}
              className={`pb-2.5 px-3 text-xs font-bold transition-all border-b-2 cursor-pointer flex items-center gap-1.5 ${
                activeTab === "loyalty"
                  ? "border-emerald-500 text-emerald-400"
                  : "border-transparent text-slate-400 hover:text-slate-200"
              }`}
            >
              <TrendingUp className="w-4 h-4" />
              <span>Spend &amp; Loyalty</span>
            </button>
          </div>

          {/* Drawer Body Area */}
          <div className="flex-1 overflow-y-auto p-5 space-y-4">
            {activeTab === "ledger" && (
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <h3 className="text-xs font-bold text-slate-300 uppercase tracking-wider">
                    Recent Transactions
                  </h3>
                  <button
                    type="button"
                    onClick={handleSendWhatsAppReminder}
                    className="text-xs font-bold text-emerald-400 hover:underline flex items-center gap-1 cursor-pointer"
                  >
                    <MessageSquare className="w-3.5 h-3.5" />
                    <span>WhatsApp Link</span>
                  </button>
                </div>

                {/* Timeline Items */}
                <div className="space-y-2.5">
                  <div className="p-3 bg-slate-950/80 border border-slate-800 rounded-2xl flex items-center justify-between">
                    <div>
                      <h4 className="text-xs font-bold text-white">Monthly Grocery Basket</h4>
                      <p className="text-[11px] text-slate-400 font-mono">
                        #INV-2026-0042 • Today, 4:30 PM • 6 items
                      </p>
                    </div>
                    <span className="text-sm font-mono font-black text-rose-400">+₹1,850.00</span>
                  </div>

                  <div className="p-3 bg-emerald-950/30 border border-emerald-800/50 rounded-2xl flex items-center justify-between">
                    <div>
                      <h4 className="text-xs font-bold text-emerald-300 flex items-center gap-1">
                        <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                        UPI Payment Received
                      </h4>
                      <p className="text-[11px] text-emerald-400/80 font-mono">
                        Ref: PhonePe QR • 2 days ago
                      </p>
                    </div>
                    <span className="text-sm font-mono font-black text-emerald-400">-₹2,000.00</span>
                  </div>

                  <div className="p-3 bg-slate-950/80 border border-slate-800 rounded-2xl flex items-center justify-between">
                    <div>
                      <h4 className="text-xs font-bold text-white">Aashirvaad Atta &amp; Dal Supplies</h4>
                      <p className="text-[11px] text-slate-400 font-mono">
                        #INV-2026-0036 • 4 days ago • 2 items
                      </p>
                    </div>
                    <span className="text-sm font-mono font-black text-rose-400">+₹740.00</span>
                  </div>
                </div>
              </div>
            )}

            {activeTab === "crates" && (
              <div className="space-y-4">
                <div className="p-3.5 bg-slate-950/80 border border-slate-800 rounded-2xl flex items-center justify-between">
                  <div>
                    <h4 className="text-xs font-bold text-white">Returnable Packaging Held</h4>
                    <p className="text-[11px] text-slate-400">Bottles, crates &amp; jars requiring customer return</p>
                  </div>
                  <div className="text-right">
                    <span className="text-[10px] text-slate-400 uppercase font-bold block">Deposit Total</span>
                    <span className="text-sm font-mono font-black text-emerald-400">
                      {formatPaise(totalDepositPaise)}
                    </span>
                  </div>
                </div>

                <div className="space-y-2">
                  {containers.map((c) => (
                    <div
                      key={c.id}
                      className="p-3 bg-slate-950/80 border border-slate-800 rounded-2xl flex items-center justify-between"
                    >
                      <div>
                        <h5 className="text-xs font-bold text-slate-200">{c.name}</h5>
                        <p className="text-[11px] text-slate-400 font-mono">
                          Deposit: {formatPaise(c.depositPerUnitPaise)} / unit • {c.lastUpdated}
                        </p>
                      </div>

                      <div className="flex items-center gap-2">
                        <span className="px-2 py-1 bg-slate-800 rounded-lg text-xs font-mono font-black text-white">
                          ×{c.count}
                        </span>
                        {c.count > 0 && (
                          <button
                            type="button"
                            onClick={() => handleReturnContainer(c.id)}
                            className="px-2.5 py-1 bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-300 border border-emerald-500/40 text-xs font-bold rounded-lg cursor-pointer transition-colors"
                          >
                            Return 1
                          </button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {activeTab === "loyalty" && (
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-3">
                  <div className="p-3.5 bg-slate-950/80 border border-slate-800 rounded-2xl">
                    <span className="text-[10px] font-bold text-slate-400 uppercase block">Lifetime Spend</span>
                    <span className="text-lg font-mono font-black text-white">₹42,850.00</span>
                    <p className="text-[10px] text-emerald-400 mt-0.5">Top 15% Customer</p>
                  </div>

                  <div className="p-3.5 bg-slate-950/80 border border-slate-800 rounded-2xl">
                    <span className="text-[10px] font-bold text-slate-400 uppercase block">Average Bill Size</span>
                    <span className="text-lg font-mono font-black text-white">₹640.00</span>
                    <p className="text-[10px] text-slate-400 mt-0.5">Visits 4x / month</p>
                  </div>
                </div>

                <div className="p-4 bg-teal-950/40 border border-teal-800/60 rounded-2xl flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="p-2.5 bg-teal-900/60 rounded-xl text-teal-300 border border-teal-700">
                      <Sparkles className="w-5 h-5" />
                    </div>
                    <div>
                      <h4 className="text-xs font-bold text-teal-200">Redeemable Reward Balance</h4>
                      <p className="text-[11px] text-teal-400/80">{customer.loyaltyPoints} points available (= ₹{customer.loyaltyPoints}.00)</p>
                    </div>
                  </div>
                  <button
                    type="button"
                    className="px-3 py-1.5 bg-teal-600 hover:bg-teal-500 text-white font-bold text-xs rounded-xl shadow-xs transition-colors cursor-pointer"
                  >
                    Redeem
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* Drawer Sticky Action Footer */}
          <div className="p-4 border-t border-slate-800 bg-slate-950/90 flex items-center gap-2">
            <button
              type="button"
              onClick={handleSendWhatsAppReminder}
              className="w-1/2 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-bold rounded-xl flex items-center justify-center gap-2 transition-colors cursor-pointer"
            >
              <MessageSquare className="w-4 h-4 text-emerald-400" />
              <span>WhatsApp Reminder</span>
            </button>

            <button
              type="button"
              onClick={() => {
                onRecordPayment?.(customer);
                onClose();
              }}
              className="w-1/2 py-2.5 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white text-xs font-black rounded-xl shadow-lg shadow-emerald-950/60 flex items-center justify-center gap-2 transition-all cursor-pointer"
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
