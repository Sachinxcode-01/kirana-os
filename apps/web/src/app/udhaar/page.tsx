"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Sidebar } from "@/components/layout/Sidebar";
import { Header } from "@/components/layout/Header";
import {
  Users,
  Search,
  Plus,
  ArrowUpRight,
  CreditCard,
  Send,
  CheckCircle2,
  AlertTriangle,
  Receipt,
  Phone,
  X,
  History,
  Printer,
  Copy,
  Share2,
  Sparkles,
  QrCode,
  DollarSign,
} from "lucide-react";
import { WebCustomer } from "@/types";
import { posAudio } from "@/utils/audioFeedback";

const INITIAL_CUSTOMERS: WebCustomer[] = [
  {
    id: "c1",
    name: "Anil Sharma",
    phone: "9880011223",
    email: "sharma.anil@gmail.com",
    address: "#42, 3rd Cross, Indiranagar",
    creditLimitPaise: 500000,
    currentBalancePaise: 185000,
    loyaltyPoints: 120,
    lastActive: "Today, 4:30 PM",
  },
  {
    id: "c2",
    name: "Sunita Patel",
    phone: "9880044556",
    email: "sunita.patel@yahoo.com",
    address: "#108, Palm Meadows",
    creditLimitPaise: 1000000,
    currentBalancePaise: 820000,
    loyaltyPoints: 250,
    lastActive: "Yesterday",
  },
  {
    id: "c3",
    name: "Rajesh Verma",
    phone: "9880077889",
    email: "rajesh.v@outlook.com",
    address: "#7, CMH Road",
    creditLimitPaise: 300000,
    currentBalancePaise: 0,
    loyaltyPoints: 85,
    lastActive: "2 days ago",
  },
  {
    id: "c4",
    name: "Pooja Reddy",
    phone: "9880022334",
    email: "pooja.reddy@gmail.com",
    address: "#24, HAL 2nd Stage",
    creditLimitPaise: 400000,
    currentBalancePaise: 360000,
    loyaltyPoints: 190,
    lastActive: "3 days ago",
  },
];

interface PaymentReceiptData {
  receiptNo: string;
  customerName: string;
  amountPaidPaise: number;
  mode: "Cash" | "UPI QR";
  prevBalancePaise: number;
  newBalancePaise: number;
  date: string;
}

export default function UdhaarLedgerPage() {
  const [customers, setCustomers] = useState<WebCustomer[]>(INITIAL_CUSTOMERS);
  const [search, setSearch] = useState("");
  const [selectedCustomer, setSelectedCustomer] = useState<WebCustomer | null>(null);
  const [settleAmount, setSettleAmount] = useState("");
  const [settleMode, setSettleMode] = useState<"Cash" | "UPI QR">("UPI QR");

  // Modals & Receipts
  const [showSettleModal, setShowSettleModal] = useState(false);
  const [showAddCustomerModal, setShowAddCustomerModal] = useState(false);
  const [showHistoryCustomer, setShowHistoryCustomer] = useState<WebCustomer | null>(null);
  const [showBulkReminderModal, setShowBulkReminderModal] = useState(false);
  const [selectedDebtorIds, setSelectedDebtorIds] = useState<string[]>([]);
  const [receiptModal, setReceiptModal] = useState<PaymentReceiptData | null>(null);
  const [mobileNavOpen, setMobileNavOpen] = useState(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // New Customer Form State
  const [newName, setNewName] = useState("");
  const [newPhone, setNewPhone] = useState("");
  const [newLimit, setNewLimit] = useState("5000");

  const totalOutstandingPaise = customers.reduce((sum, c) => sum + c.currentBalancePaise, 0);
  const highRiskCount = customers.filter(
    (c) => c.creditLimitPaise > 0 && c.currentBalancePaise / c.creditLimitPaise >= 0.8
  ).length;

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

  const filteredCustomers = customers.filter(
    (c) =>
      c.name.toLowerCase().includes(search.toLowerCase()) ||
      c.phone.includes(search)
  );

  const formatRupees = (paise: number) =>
    `₹${(paise / 100).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

  const handleSettle = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedCustomer || !settleAmount) return;

    const settlePaise = Math.round(parseFloat(settleAmount) * 100);
    const prevBalance = selectedCustomer.currentBalancePaise;
    const newBalance = Math.max(0, prevBalance - settlePaise);

    setCustomers(
      customers.map((c) =>
        c.id === selectedCustomer.id
          ? { ...c, currentBalancePaise: newBalance }
          : c
      )
    );

    // Generate digital receipt
    setReceiptModal({
      receiptNo: "RCPT-" + String(Date.now()).slice(-6),
      customerName: selectedCustomer.name,
      amountPaidPaise: settlePaise,
      mode: settleMode,
      prevBalancePaise: prevBalance,
      newBalancePaise: newBalance,
      date: new Date().toLocaleString("en-IN"),
    });

    setShowSettleModal(false);
    setSettleAmount("");
    posAudio.playSuccessChime();
    showToast(`Payment of ${formatRupees(settlePaise)} recorded for ${selectedCustomer.name}`);
  };

  const handleAddCustomer = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName.trim() || !newPhone.trim()) return;

    const newCust: WebCustomer = {
      id: "c_" + Date.now(),
      name: newName.trim(),
      phone: newPhone.trim(),
      creditLimitPaise: Math.round(parseFloat(newLimit || "0") * 100),
      currentBalancePaise: 0,
      loyaltyPoints: 0,
      lastActive: "Just added",
    };

    setCustomers([newCust, ...customers]);
    setShowAddCustomerModal(false);
    setNewName("");
    setNewPhone("");
    posAudio.playSuccessChime();
    showToast(`Added ${newCust.name} to Khata ledger.`);
  };

  const triggerWhatsAppReminder = (customer: WebCustomer) => {
    posAudio.playBarcodeBeep();
    const upiLink = `upi://pay?pa=srilakshmi@okaxis&pn=Sri%20Lakshmi%20Provision&am=${(
      customer.currentBalancePaise / 100
    ).toFixed(2)}&cu=INR`;
    const message = `Namaste *${customer.name}* ji, 🙏\n\nSri Lakshmi Provision Stores par aapka pending udhaar khata balance *${formatRupees(
      customer.currentBalancePaise
    )}* hai.\n\nKripya neeche diye gaye link se instant UPI payment karein:\n👉 ${upiLink}\n\nDhanyawad! 🙏`;

    const encoded = encodeURIComponent(message);
    const cleanPhone = customer.phone.replace(/\D/g, "");
    window.open(`https://wa.me/91${cleanPhone}?text=${encoded}`, "_blank");
    showToast(`WhatsApp UPI reminder opened for ${customer.name}`);
  };

  return (
    <div className="flex min-h-screen bg-slate-50 relative overflow-hidden">
      {/* Ambient background glow */}
      <div className="absolute top-0 right-0 w-96 h-96 bg-amber-400/10 rounded-full blur-3xl pointer-events-none"></div>

      <Sidebar isOpen={mobileNavOpen} onClose={() => setMobileNavOpen(false)} />

      <div className="flex-1 flex flex-col min-w-0 z-10">
        <Header
          title="Customer Udhaar (Khata) Ledger"
          subtitle="Real-time credit monitoring, payment settlements, and 1-tap WhatsApp reminders"
          onMenuClick={() => setMobileNavOpen(true)}
        />

        <main className="p-4 sm:p-6 lg:p-8 space-y-6 flex-1 overflow-auto">
          {/* Notification Toast */}
          <AnimatePresence>
            {toastMessage && (
              <motion.div
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                className="p-3.5 bg-emerald-600 text-white rounded-2xl shadow-lg flex items-center justify-between gap-3 text-xs font-bold"
              >
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-emerald-200" />
                  <span>{toastMessage}</span>
                </div>
                <button
                  type="button"
                  onClick={() => setToastMessage(null)}
                  className="p-1 hover:bg-emerald-700 rounded-lg cursor-pointer"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              </motion.div>
            )}
          </AnimatePresence>

          {/* KPI Summary Banner */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
            <div className="p-6 bg-gradient-to-tr from-slate-900 to-slate-800 text-white rounded-2xl shadow-md flex items-center justify-between">
              <div>
                <p className="text-xs text-slate-400 font-bold uppercase tracking-wider">
                  Total Outstanding Khata
                </p>
                <h3 className="text-3xl font-black font-mono mt-2 text-white">
                  {formatRupees(totalOutstandingPaise)}
                </h3>
                <p className="text-xs text-amber-400 font-medium mt-1">4 Active Debtors</p>
              </div>
              <div className="p-3 bg-amber-500/20 border border-amber-500/30 text-amber-400 rounded-2xl">
                <CreditCard className="w-6 h-6" />
              </div>
            </div>

            <div className="p-6 glass-card rounded-2xl shadow-xs flex items-center justify-between">
              <div>
                <p className="text-xs text-slate-500 font-bold uppercase tracking-wider">
                  Credit Limit Utilization
                </p>
                <h3 className="text-3xl font-black font-mono mt-2 text-slate-900">
                  {highRiskCount} High Risk
                </h3>
                <p className="text-xs text-rose-600 font-bold mt-1">&ge;80% Limit Exceeded</p>
              </div>
              <div className="p-3 bg-rose-50 text-rose-600 rounded-2xl border border-rose-100">
                <AlertTriangle className="w-6 h-6" />
              </div>
            </div>

            <div className="p-6 glass-card rounded-2xl shadow-xs flex items-center justify-between">
              <div>
                <p className="text-xs text-slate-500 font-bold uppercase tracking-wider">
                  Registered Khata Accounts
                </p>
                <h3 className="text-3xl font-black font-mono mt-2 text-slate-900">
                  {customers.length} Customers
                </h3>
                <p className="text-xs text-emerald-600 font-bold mt-1">100% Local Verification</p>
              </div>
              <div className="p-3 bg-emerald-50 text-emerald-600 rounded-2xl border border-emerald-100">
                <Users className="w-6 h-6" />
              </div>
            </div>
          </div>

          {/* Search & Actions Bar */}
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4 glass-card p-4 rounded-2xl shadow-xs">
            <div className="relative flex-1 max-w-md">
              <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search customer by name or phone number..."
                className="w-full pl-9 pr-4 py-2 bg-slate-100/90 hover:bg-slate-100 focus:bg-white text-xs text-slate-800 rounded-xl border border-slate-200/80 focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/10 focus:outline-none transition-all placeholder:text-slate-400 font-medium"
              />
            </div>

            <div className="flex items-center gap-2 sm:gap-3">
              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={() => {
                  const debtors = customers.filter((c) => c.currentBalancePaise > 0).map((c) => c.id);
                  setSelectedDebtorIds(debtors);
                  setShowBulkReminderModal(true);
                }}
                className="flex items-center gap-2 px-3.5 py-2 bg-emerald-50 hover:bg-emerald-100 text-emerald-800 border border-emerald-300 rounded-xl text-xs font-bold shadow-xs transition-all cursor-pointer whitespace-nowrap"
              >
                <Send className="w-3.5 h-3.5 text-emerald-600" />
                <span>Bulk WhatsApp Reminders</span>
                <span className="px-1.5 py-0.2 rounded bg-emerald-200 text-[10px] font-mono font-black text-emerald-900">
                  {customers.filter((c) => c.currentBalancePaise > 0).length}
                </span>
              </motion.button>
              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={() => setShowAddCustomerModal(true)}
                className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 text-white rounded-xl text-xs font-bold shadow-md shadow-emerald-950/20 transition-all cursor-pointer whitespace-nowrap"
              >
                <Plus className="w-4 h-4" />
                <span>Add Khata Customer</span>
              </motion.button>
            </div>
          </div>

          {/* Customers Table */}
          <div className="glass-card rounded-2xl shadow-xs overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="bg-slate-100/70 border-b border-slate-200 text-[11px] font-bold text-slate-600 uppercase tracking-wider">
                    <th className="py-3.5 px-4">Customer Name & Phone</th>
                    <th className="py-3.5 px-4 text-right">Credit Limit</th>
                    <th className="py-3.5 px-4 text-right">Current Udhaar Balance</th>
                    <th className="py-3.5 px-4 text-center">Utilization</th>
                    <th className="py-3.5 px-4 text-center">Loyalty Stars</th>
                    <th className="py-3.5 px-4 text-center">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-xs text-slate-700 font-medium">
                  {filteredCustomers.map((cust) => {
                    const ratio =
                      cust.creditLimitPaise > 0
                        ? Math.min(100, Math.round((cust.currentBalancePaise / cust.creditLimitPaise) * 100))
                        : 0;
                    const isHighRisk = ratio >= 80;

                    return (
                      <tr key={cust.id} className="hover:bg-slate-50/70 transition-colors">
                        <td className="py-3 px-4">
                          <div className="font-bold text-slate-900">{cust.name}</div>
                          <div className="text-[11px] text-slate-500 font-mono flex items-center gap-1">
                            <Phone className="w-3 h-3 text-slate-400" /> +91 {cust.phone}
                          </div>
                        </td>
                        <td className="py-3 px-4 text-right font-mono text-slate-600">
                          {formatRupees(cust.creditLimitPaise)}
                        </td>
                        <td className="py-3 px-4 text-right font-mono font-bold text-slate-900">
                          <span className={cust.currentBalancePaise > 0 ? "text-amber-700" : "text-emerald-700"}>
                            {formatRupees(cust.currentBalancePaise)}
                          </span>
                        </td>
                        <td className="py-3 px-4 text-center">
                          <div className="flex flex-col items-center gap-1">
                            <div className="w-24 bg-slate-100 h-2 rounded-full overflow-hidden border border-slate-200/60">
                              <div
                                className={`h-full rounded-full transition-all ${
                                  isHighRisk ? "bg-rose-500" : "bg-emerald-500"
                                }`}
                                style={{ width: `${ratio}%` }}
                              />
                            </div>
                            <span className="text-[10px] font-bold text-slate-500">{ratio}% Limit Used</span>
                          </div>
                        </td>
                        <td className="py-3 px-4 text-center">
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-bold bg-amber-50 text-amber-800 border border-amber-200">
                            ⭐ {cust.loyaltyPoints} pts
                          </span>
                        </td>
                        <td className="py-3 px-4 text-center">
                          <div className="flex items-center justify-center gap-1.5">
                            {cust.currentBalancePaise > 0 && (
                              <button
                                type="button"
                                onClick={() => {
                                  setSelectedCustomer(cust);
                                  setSettleAmount((cust.currentBalancePaise / 100).toFixed(2));
                                  setShowSettleModal(true);
                                }}
                                className="px-3 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg font-bold text-[11px] shadow-xs transition-colors cursor-pointer"
                              >
                                Record Payment
                              </button>
                            )}

                            {cust.currentBalancePaise > 0 && (
                              <button
                                type="button"
                                onClick={() => triggerWhatsAppReminder(cust)}
                                className="p-1.5 rounded-lg text-emerald-700 hover:bg-emerald-50 border border-emerald-200 transition-colors cursor-pointer"
                                title="Send WhatsApp Payment Reminder"
                              >
                                <Send className="w-3.5 h-3.5" />
                              </button>
                            )}

                            <button
                              type="button"
                              onClick={() => setShowHistoryCustomer(cust)}
                              className="p-1.5 rounded-lg text-slate-500 hover:bg-slate-100 transition-colors cursor-pointer"
                              title="View Khata Ledger History"
                            >
                              <History className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            <div className="p-4 border-t border-slate-100 bg-slate-50/50 flex items-center justify-between text-xs text-slate-500">
              <span>Showing {filteredCustomers.length} active customer accounts</span>
              <span className="font-semibold text-emerald-700 flex items-center gap-1">
                <Sparkles className="w-3.5 h-3.5 text-amber-500" /> WhatsApp UPI Direct Intent Enabled
              </span>
            </div>
          </div>
        </main>
      </div>

      {/* Modal 1: Record Khata Payment */}
      <AnimatePresence>
        {showSettleModal && selectedCustomer && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-sm bg-white rounded-3xl p-6 shadow-2xl space-y-4"
            >
              <div className="flex items-center justify-between pb-2 border-b border-slate-100">
                <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <CreditCard className="w-4 h-4 text-emerald-600" /> Record Khata Payment
                </h3>
                <button
                  type="button"
                  onClick={() => setShowSettleModal(false)}
                  className="text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 text-xs space-y-1">
                <p className="font-bold text-slate-900">{selectedCustomer.name}</p>
                <p className="text-slate-500">
                  Total Outstanding:{" "}
                  <strong className="text-amber-700 font-mono font-bold">
                    {formatRupees(selectedCustomer.currentBalancePaise)}
                  </strong>
                </p>
              </div>

              <form onSubmit={handleSettle} className="space-y-4 text-xs">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Amount Received (₹)</label>
                  <input
                    type="number"
                    step="0.01"
                    min="1"
                    required
                    value={settleAmount}
                    onChange={(e) => setSettleAmount(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 font-mono font-bold text-center text-lg text-slate-900 focus:bg-white focus:outline-none focus:border-emerald-500"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">Payment Method</label>
                  <div className="grid grid-cols-2 gap-2">
                    <button
                      type="button"
                      onClick={() => setSettleMode("UPI QR")}
                      className={`py-2 rounded-xl font-bold border cursor-pointer flex items-center justify-center gap-1.5 ${
                        settleMode === "UPI QR"
                          ? "bg-teal-50 text-teal-800 border-teal-300 shadow-xs"
                          : "bg-slate-50 text-slate-600 border-slate-200"
                      }`}
                    >
                      <QrCode className="w-4 h-4 text-teal-600" />
                      <span>UPI QR</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => setSettleMode("Cash")}
                      className={`py-2 rounded-xl font-bold border cursor-pointer flex items-center justify-center gap-1.5 ${
                        settleMode === "Cash"
                          ? "bg-emerald-50 text-emerald-800 border-emerald-300 shadow-xs"
                          : "bg-slate-50 text-slate-600 border-slate-200"
                      }`}
                    >
                      <DollarSign className="w-4 h-4 text-emerald-600" />
                      <span>Cash Inflow</span>
                    </button>
                  </div>
                </div>

                <div className="pt-2 border-t border-slate-100 flex items-center justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => setShowSettleModal(false)}
                    className="px-3.5 py-1.5 rounded-xl text-slate-600 hover:bg-slate-100 font-semibold cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold cursor-pointer shadow-md shadow-emerald-950/20"
                  >
                    Confirm &amp; Issue Receipt
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Modal 2: Payment Receipt Stencil */}
      <AnimatePresence>
        {receiptModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-sm bg-white rounded-3xl p-6 shadow-2xl space-y-4"
            >
              <div className="flex items-center justify-between pb-2 border-b border-slate-100">
                <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <Receipt className="w-4 h-4 text-emerald-600" /> Digital Payment Receipt
                </h3>
                <button
                  type="button"
                  onClick={() => setReceiptModal(null)}
                  className="text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <div className="p-4 bg-slate-50 border border-slate-200 rounded-2xl text-xs space-y-2 font-mono">
                <div className="text-center pb-2 border-b border-slate-200/80 font-sans">
                  <p className="font-extrabold text-sm text-slate-900">Sri Lakshmi Provision</p>
                  <p className="text-[10px] text-slate-500">Bengaluru • GSTIN: 29AAAAA0000A1Z5</p>
                </div>

                <div className="flex justify-between text-slate-600">
                  <span>Receipt No:</span>
                  <span className="font-bold text-slate-900">{receiptModal.receiptNo}</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span>Customer:</span>
                  <span className="font-bold text-slate-900">{receiptModal.customerName}</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span>Payment Mode:</span>
                  <span className="font-bold text-emerald-700">{receiptModal.mode}</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span>Date &amp; Time:</span>
                  <span className="text-[11px]">{receiptModal.date}</span>
                </div>

                <div className="pt-2 border-t border-slate-200 space-y-1 font-bold">
                  <div className="flex justify-between text-slate-700">
                    <span>Previous Debt:</span>
                    <span>{formatRupees(receiptModal.prevBalancePaise)}</span>
                  </div>
                  <div className="flex justify-between text-emerald-700 text-sm">
                    <span>Amount Paid:</span>
                    <span>{formatRupees(receiptModal.amountPaidPaise)}</span>
                  </div>
                  <div className="flex justify-between text-slate-900 pt-1 border-t border-slate-200/60">
                    <span>Remaining Balance:</span>
                    <span>{formatRupees(receiptModal.newBalancePaise)}</span>
                  </div>
                </div>

                <p className="text-center text-[10px] text-slate-400 pt-2 font-sans">
                  Thank you! KiranaOS Verified Receipt
                </p>
              </div>

              <div className="pt-2 flex items-center justify-end gap-2 text-xs">
                <button
                  type="button"
                  onClick={() => setReceiptModal(null)}
                  className="px-3 py-1.5 rounded-xl text-slate-600 hover:bg-slate-100 font-semibold cursor-pointer"
                >
                  Close
                </button>
                <button
                  type="button"
                  onClick={() => {
                    alert(`Receipt ${receiptModal.receiptNo} printed to thermal printer.`);
                    setReceiptModal(null);
                  }}
                  className="px-4 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold cursor-pointer flex items-center gap-1.5"
                >
                  <Printer className="w-3.5 h-3.5" />
                  <span>Print Receipt</span>
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Modal 3: Add Khata Customer */}
      <AnimatePresence>
        {showAddCustomerModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-sm bg-white rounded-3xl p-6 shadow-2xl space-y-4"
            >
              <div className="flex items-center justify-between pb-2 border-b border-slate-100">
                <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <Plus className="w-4 h-4 text-emerald-600" /> New Khata Customer Account
                </h3>
                <button
                  type="button"
                  onClick={() => setShowAddCustomerModal(false)}
                  className="text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <form onSubmit={handleAddCustomer} className="space-y-3 text-xs">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Customer Full Name</label>
                  <input
                    type="text"
                    required
                    value={newName}
                    onChange={(e) => setNewName(e.target.value)}
                    placeholder="e.g. Meena Raghavan"
                    className="w-full px-3.5 py-2 rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:outline-none focus:border-emerald-500"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">WhatsApp / Phone Number</label>
                  <input
                    type="tel"
                    required
                    value={newPhone}
                    onChange={(e) => setNewPhone(e.target.value)}
                    placeholder="e.g. 9845012345"
                    className="w-full px-3.5 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono focus:bg-white focus:outline-none focus:border-emerald-500"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">Credit Limit (₹)</label>
                  <input
                    type="number"
                    min="500"
                    step="500"
                    value={newLimit}
                    onChange={(e) => setNewLimit(e.target.value)}
                    className="w-full px-3.5 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono focus:bg-white focus:outline-none focus:border-emerald-500"
                  />
                </div>

                <div className="pt-2 border-t border-slate-100 flex items-center justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => setShowAddCustomerModal(false)}
                    className="px-3.5 py-1.5 rounded-xl text-slate-600 hover:bg-slate-100 font-semibold cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold cursor-pointer"
                  >
                    Create Account
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Modal 4: Customer Khata Ledger History */}
      <AnimatePresence>
        {showHistoryCustomer && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl space-y-4"
            >
              <div className="flex items-center justify-between pb-2 border-b border-slate-100">
                <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <History className="w-4 h-4 text-emerald-600" /> Khata Statement: {showHistoryCustomer.name}
                </h3>
                <button
                  type="button"
                  onClick={() => setShowHistoryCustomer(null)}
                  className="text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 text-xs flex justify-between items-center">
                <span>Current Debt Balance:</span>
                <span className="font-bold font-mono text-amber-800 text-sm">
                  {formatRupees(showHistoryCustomer.currentBalancePaise)}
                </span>
              </div>

              {/* Sample Statement Ledger */}
              <div className="space-y-2 text-xs font-mono max-h-60 overflow-y-auto">
                <div className="p-2.5 bg-white border border-slate-200 rounded-xl flex items-center justify-between">
                  <div>
                    <p className="font-bold text-slate-900 font-sans">Grocery Basket Purchase</p>
                    <p className="text-[10px] text-slate-400">Bill #INV-2026-0042 &bull; Today</p>
                  </div>
                  <span className="font-bold text-rose-600">+₹1,850.00</span>
                </div>
                <div className="p-2.5 bg-emerald-50/50 border border-emerald-200 rounded-xl flex items-center justify-between">
                  <div>
                    <p className="font-bold text-emerald-950 font-sans">UPI Khata Payment Received</p>
                    <p className="text-[10px] text-emerald-600 font-sans">Ref: BharatPe QR</p>
                  </div>
                  <span className="font-bold text-emerald-700">-₹2,000.00</span>
                </div>
                <div className="p-2.5 bg-white border border-slate-200 rounded-xl flex items-center justify-between">
                  <div>
                    <p className="font-bold text-slate-900 font-sans">Dairy &amp; Tea Supplies</p>
                    <p className="text-[10px] text-slate-400">Bill #INV-2026-0038 &bull; Yesterday</p>
                  </div>
                  <span className="font-bold text-rose-600">+₹950.00</span>
                </div>
              </div>

              <div className="pt-2 border-t border-slate-100 flex items-center justify-end gap-2 text-xs">
                <button
                  type="button"
                  onClick={() => setShowHistoryCustomer(null)}
                  className="px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold cursor-pointer"
                >
                  Done
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Modal 4: Bulk WhatsApp Reminders & Dynamic UPI Pay Links (Phase 16) */}
      <AnimatePresence>
        {showBulkReminderModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-xl bg-white rounded-3xl p-6 shadow-2xl space-y-4 max-h-[90vh] overflow-y-auto"
            >
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-2.5">
                  <div className="p-2 bg-emerald-100 text-emerald-700 rounded-xl">
                    <Send className="w-5 h-5" />
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-900 text-base">
                      Bulk WhatsApp Khata Payment Reminders
                    </h3>
                    <p className="text-xs text-slate-500">
                      Dispatches direct UPI Payment Links with shop VPA
                    </p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setShowBulkReminderModal(false)}
                  className="text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* Debtors List with checkboxes */}
              <div className="space-y-2">
                <div className="flex items-center justify-between text-xs text-slate-500 font-semibold px-1">
                  <span>Select Debtors ({selectedDebtorIds.length} selected)</span>
                  <button
                    type="button"
                    onClick={() => {
                      const all = customers.filter((c) => c.currentBalancePaise > 0).map((c) => c.id);
                      setSelectedDebtorIds(selectedDebtorIds.length === all.length ? [] : all);
                    }}
                    className="text-emerald-600 hover:underline font-bold cursor-pointer"
                  >
                    {selectedDebtorIds.length === customers.filter((c) => c.currentBalancePaise > 0).length
                      ? "Deselect All"
                      : "Select All"}
                  </button>
                </div>

                <div className="space-y-2 max-h-60 overflow-y-auto pr-1">
                  {customers
                    .filter((c) => c.currentBalancePaise > 0)
                    .map((c) => {
                      const isSelected = selectedDebtorIds.includes(c.id);
                      return (
                        <div
                          key={c.id}
                          onClick={() => {
                            setSelectedDebtorIds((prev) =>
                              isSelected ? prev.filter((id) => id !== c.id) : [...prev, c.id]
                            );
                          }}
                          className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-colors ${
                            isSelected
                              ? "bg-emerald-50/70 border-emerald-300"
                              : "bg-slate-50 border-slate-200 text-slate-500"
                          }`}
                        >
                          <div className="flex items-center gap-3">
                            <input
                              type="checkbox"
                              checked={isSelected}
                              onChange={() => {}}
                              className="rounded text-emerald-600 focus:ring-emerald-500"
                            />
                            <div>
                              <p className="font-bold text-slate-900 text-xs">{c.name}</p>
                              <p className="text-[11px] text-slate-500 font-mono">{c.phone}</p>
                            </div>
                          </div>
                          <span className="font-bold font-mono text-xs text-rose-600">
                            {formatRupees(c.currentBalancePaise)}
                          </span>
                        </div>
                      );
                    })}
                </div>
              </div>

              {/* Message & UPI Pay Link Preview */}
              <div className="p-3 bg-slate-50 rounded-2xl border border-slate-200 space-y-2">
                <div className="flex items-center justify-between text-[11px] font-bold text-slate-600 uppercase">
                  <span>WhatsApp Message Preview</span>
                  <span className="text-emerald-700">UPI Intent Active</span>
                </div>
                <div className="p-3 bg-white rounded-xl border border-slate-200 text-xs text-slate-700 font-mono space-y-1">
                  <p className="font-bold text-slate-900">Sri Lakshmi Provision Store</p>
                  <p className="text-slate-600">Dear Customer, you have a pending Khata balance.</p>
                  <p className="text-emerald-700 font-bold">
                    📲 Pay instantly via UPI: upi://pay?pa=srilakshmi@okaxis&amp;pn=SriLakshmiProvision
                  </p>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="pt-2 border-t border-slate-100 flex items-center justify-end gap-2 text-xs">
                <button
                  type="button"
                  onClick={() => setShowBulkReminderModal(false)}
                  className="px-4 py-2 rounded-xl text-slate-600 hover:bg-slate-100 font-semibold cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  disabled={selectedDebtorIds.length === 0}
                  onClick={() => {
                    posAudio.playSuccessChime();
                    showToast(`Dispatched WhatsApp reminders to ${selectedDebtorIds.length} customers.`);
                    setShowBulkReminderModal(false);
                  }}
                  className="px-4 py-2 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 disabled:opacity-50 text-white font-bold shadow-md shadow-emerald-950/20 cursor-pointer flex items-center gap-2"
                >
                  <Send className="w-3.5 h-3.5" />
                  <span>Send {selectedDebtorIds.length} WhatsApp Reminders</span>
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
