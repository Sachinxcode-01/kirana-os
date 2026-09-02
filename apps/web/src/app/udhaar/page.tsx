"use client";

import React, { useState } from "react";
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
} from "lucide-react";
import { WebCustomer } from "@/types";

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

export default function UdhaarLedgerPage() {
  const [customers, setCustomers] = useState<WebCustomer[]>(INITIAL_CUSTOMERS);
  const [search, setSearch] = useState("");
  const [selectedCustomer, setSelectedCustomer] = useState<WebCustomer | null>(null);
  const [settleAmount, setSettleAmount] = useState("");
  const [settleMode, setSettleMode] = useState<"cash" | "upi_qr">("upi_qr");
  const [showSettleModal, setShowSettleModal] = useState(false);
  const [showHistoryModal, setShowHistoryModal] = useState(false);
  const [showAddCustomerModal, setShowAddCustomerModal] = useState(false);

  // New Customer Form State
  const [newName, setNewName] = useState("");
  const [newPhone, setNewPhone] = useState("");
  const [newLimit, setNewLimit] = useState("5000");

  const totalOutstandingPaise = customers.reduce((sum, c) => sum + c.currentBalancePaise, 0);
  const highRiskCount = customers.filter(
    (c) => c.creditLimitPaise > 0 && c.currentBalancePaise / c.creditLimitPaise >= 0.8
  ).length;

  const filteredCustomers = customers.filter(
    (c) =>
      c.name.toLowerCase().includes(search.toLowerCase()) ||
      c.phone.includes(search)
  );

  const formatRupees = (paise: number) => `₹${(paise / 100).toFixed(2)}`;

  const handleSettle = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedCustomer || !settleAmount) return;

    const settlePaise = Math.round(parseFloat(settleAmount) * 100);
    setCustomers(
      customers.map((c) =>
        c.id === selectedCustomer.id
          ? { ...c, currentBalancePaise: Math.max(0, c.currentBalancePaise - settlePaise) }
          : c
      )
    );

    setShowSettleModal(false);
    setSettleAmount("");
  };

  const handleAddCustomer = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newName || !newPhone) return;

    const newCust: WebCustomer = {
      id: "c_" + Date.now(),
      name: newName,
      phone: newPhone,
      creditLimitPaise: Math.round(parseFloat(newLimit || "0") * 100),
      currentBalancePaise: 0,
      loyaltyPoints: 0,
      lastActive: "Just added",
    };

    setCustomers([newCust, ...customers]);
    setShowAddCustomerModal(false);
    setNewName("");
    setNewPhone("");
  };

  const triggerWhatsAppReminder = (customer: WebCustomer) => {
    const upiLink = `upi://pay?pa=srilakshmi@okaxis&pn=Sri%20Lakshmi%20Provision&am=${(
      customer.currentBalancePaise / 100
    ).toFixed(2)}&cu=INR`;
    const message = `Namaste *${customer.name}* ji,\n\nSri Lakshmi Provision Stores par aapka pending udhaar balance *${formatRupees(
      customer.currentBalancePaise
    )}* hai.\n\nKripya neeche diye gaye link se instant UPI payment karein:\n👉 ${upiLink}\n\nDhanyawad! 🙏`;

    const encoded = encodeURIComponent(message);
    const cleanPhone = customer.phone.replace(/\D/g, "");
    window.open(`https://wa.me/91${cleanPhone}?text=${encoded}`, "_blank");
  };

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />

      <div className="flex-1 flex flex-col min-w-0">
        <Header
          title="Customer Udhaar (Khata) Ledger"
          subtitle="Real-time credit monitoring, payment settlements, and 1-tap WhatsApp reminders"
        />

        <main className="p-8 space-y-6 flex-1 overflow-auto">
          {/* KPI Summary Banner */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
            <div className="p-5 bg-gradient-to-tr from-slate-900 to-slate-800 text-white rounded-2xl shadow-md flex items-center justify-between">
              <div>
                <p className="text-xs text-slate-400 font-semibold uppercase tracking-wider">
                  Total Outstanding Udhaar
                </p>
                <h3 className="text-2xl font-extrabold font-mono mt-1 text-white">
                  {formatRupees(totalOutstandingPaise)}
                </h3>
                <p className="text-[11px] text-emerald-400 mt-1">Across {customers.length} khata accounts</p>
              </div>
              <div className="p-3 bg-white/10 rounded-xl text-emerald-400">
                <CreditCard className="w-6 h-6" />
              </div>
            </div>

            <div className="p-5 bg-white rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
              <div>
                <p className="text-xs text-slate-500 font-semibold uppercase tracking-wider">
                  High Risk Limit Breach
                </p>
                <h3 className="text-2xl font-extrabold font-mono mt-1 text-rose-600">
                  {highRiskCount} Accounts
                </h3>
                <p className="text-[11px] text-slate-400 mt-1">&gt;80% of allowed credit limit</p>
              </div>
              <div className="p-3 bg-rose-50 rounded-xl text-rose-600">
                <AlertTriangle className="w-6 h-6" />
              </div>
            </div>

            <div className="p-5 bg-white rounded-2xl border border-slate-200/80 shadow-xs flex items-center justify-between">
              <div>
                <p className="text-xs text-slate-500 font-semibold uppercase tracking-wider">
                  Today&apos;s Collections
                </p>
                <h3 className="text-2xl font-extrabold font-mono mt-1 text-emerald-600">
                  ₹4,200.00
                </h3>
                <p className="text-[11px] text-slate-400 mt-1">3 customers settled via UPI</p>
              </div>
              <div className="p-3 bg-emerald-50 rounded-xl text-emerald-600">
                <CheckCircle2 className="w-6 h-6" />
              </div>
            </div>
          </div>

          {/* Search & Actions Bar */}
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4 bg-white p-4 rounded-2xl border border-slate-200/80 shadow-xs">
            <div className="relative flex-1 max-w-md">
              <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search customers by name or 10-digit mobile number..."
                className="w-full pl-10 pr-4 py-2 bg-slate-50 hover:bg-slate-100/80 focus:bg-white text-xs text-slate-800 rounded-xl border border-slate-200 focus:border-emerald-500 focus:outline-none transition-all"
              />
            </div>

            <button
              type="button"
              onClick={() => setShowAddCustomerModal(true)}
              className="flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 shadow-sm shadow-emerald-800/30 transition-all"
            >
              <Plus className="w-4 h-4" /> Add Khata Customer
            </button>
          </div>

          {/* Customer Khata Table */}
          <div className="bg-white rounded-2xl border border-slate-200/80 shadow-xs overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50/80 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                    <th className="py-3.5 px-4">Customer Details</th>
                    <th className="py-3.5 px-4 text-right">Outstanding Due</th>
                    <th className="py-3.5 px-4 text-right">Credit Limit</th>
                    <th className="py-3.5 px-4">Limit Utilization</th>
                    <th className="py-3.5 px-4 text-center">Loyalty Points</th>
                    <th className="py-3.5 px-4 text-right">Last Activity</th>
                    <th className="py-3.5 px-4 text-center">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-xs text-slate-700 font-medium">
                  {filteredCustomers.map((c) => {
                    const pct = c.creditLimitPaise > 0 ? (c.currentBalancePaise / c.creditLimitPaise) * 100 : 0;
                    const isOverLimit = pct >= 80;

                    return (
                      <tr key={c.id} className="hover:bg-slate-50/60 transition-colors">
                        <td className="py-3 px-4">
                          <div className="font-bold text-slate-900">{c.name}</div>
                          <div className="text-[11px] text-slate-400 font-normal flex items-center gap-1.5 mt-0.5">
                            <Phone className="w-3 h-3 text-slate-400" /> +91 {c.phone}
                          </div>
                        </td>
                        <td className="py-3 px-4 text-right font-mono">
                          <span
                            className={`font-bold ${
                              c.currentBalancePaise > 0 ? "text-rose-600" : "text-slate-400"
                            }`}
                          >
                            {formatRupees(c.currentBalancePaise)}
                          </span>
                        </td>
                        <td className="py-3 px-4 text-right font-mono text-slate-600">
                          {formatRupees(c.creditLimitPaise)}
                        </td>
                        <td className="py-3 px-4">
                          <div className="w-36">
                            <div className="flex justify-between text-[10px] text-slate-500 mb-1">
                              <span>{pct.toFixed(0)}%</span>
                              <span>{isOverLimit ? "⚠️ High Risk" : "Normal"}</span>
                            </div>
                            <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                              <div
                                className={`h-full rounded-full ${
                                  isOverLimit ? "bg-rose-500" : "bg-emerald-500"
                                }`}
                                style={{ width: `${Math.min(pct, 100)}%` }}
                              ></div>
                            </div>
                          </div>
                        </td>
                        <td className="py-3 px-4 text-center">
                          <span className="px-2.5 py-1 rounded-full text-[11px] font-bold bg-amber-50 text-amber-700 border border-amber-200">
                            ⭐ {c.loyaltyPoints} pts
                          </span>
                        </td>
                        <td className="py-3 px-4 text-right text-[11px] text-slate-400">
                          {c.lastActive || "Recently"}
                        </td>
                        <td className="py-3 px-4 text-center">
                          <div className="flex items-center justify-center gap-2">
                            {c.currentBalancePaise > 0 && (
                              <button
                                type="button"
                                onClick={() => triggerWhatsAppReminder(c)}
                                className="flex items-center gap-1 px-2.5 py-1 rounded-lg text-[11px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200 hover:bg-emerald-100 transition-colors"
                                title="Send WhatsApp UPI Reminder"
                              >
                                <Send className="w-3 h-3" /> Remind
                              </button>
                            )}
                            <button
                              type="button"
                              onClick={() => {
                                setSelectedCustomer(c);
                                setSettleAmount((c.currentBalancePaise / 100).toFixed(2));
                                setShowSettleModal(true);
                              }}
                              className="px-2.5 py-1 rounded-lg text-[11px] font-bold bg-slate-900 text-white hover:bg-slate-800 transition-colors"
                            >
                              Settle
                            </button>
                            <button
                              type="button"
                              onClick={() => {
                                setSelectedCustomer(c);
                                setShowHistoryModal(true);
                              }}
                              className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-100 hover:text-slate-700 transition-colors"
                              title="View Khata Statement"
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
          </div>
        </main>
      </div>

      {/* Settle Khata Modal */}
      {showSettleModal && selectedCustomer && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="bg-white w-full max-w-md rounded-2xl shadow-2xl border border-slate-200 overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between">
              <div>
                <h3 className="font-bold text-slate-900 text-base">Settle Customer Khata</h3>
                <p className="text-xs text-slate-500">Record partial or full payment receipt</p>
              </div>
              <button
                type="button"
                onClick={() => setShowSettleModal(false)}
                className="text-slate-400 hover:text-slate-700"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSettle} className="p-6 space-y-4 text-xs">
              <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 flex justify-between items-center">
                <div>
                  <p className="font-bold text-slate-900">{selectedCustomer.name}</p>
                  <p className="text-[11px] text-slate-500">+91 {selectedCustomer.phone}</p>
                </div>
                <div className="text-right">
                  <p className="text-[10px] text-slate-400 uppercase font-semibold">Current Due</p>
                  <p className="font-bold font-mono text-rose-600 text-sm">
                    {formatRupees(selectedCustomer.currentBalancePaise)}
                  </p>
                </div>
              </div>

              <div>
                <label className="font-bold text-slate-700 block mb-1">Settlement Amount (₹)</label>
                <input
                  type="number"
                  step="0.01"
                  required
                  value={settleAmount}
                  onChange={(e) => setSettleAmount(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-slate-50 rounded-xl border border-slate-200 text-sm font-bold font-mono text-emerald-700 focus:bg-white focus:border-emerald-500 focus:outline-none"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 block mb-1">Payment Mode</label>
                <div className="grid grid-cols-2 gap-3">
                  <button
                    type="button"
                    onClick={() => setSettleMode("upi_qr")}
                    className={`py-2 rounded-xl border font-semibold text-xs transition-all ${
                      settleMode === "upi_qr"
                        ? "bg-emerald-50 border-emerald-500 text-emerald-800"
                        : "bg-slate-50 border-slate-200 text-slate-600"
                    }`}
                  >
                    UPI / Bharat QR
                  </button>
                  <button
                    type="button"
                    onClick={() => setSettleMode("cash")}
                    className={`py-2 rounded-xl border font-semibold text-xs transition-all ${
                      settleMode === "cash"
                        ? "bg-emerald-50 border-emerald-500 text-emerald-800"
                        : "bg-slate-50 border-slate-200 text-slate-600"
                    }`}
                  >
                    Physical Cash
                  </button>
                </div>
              </div>

              <div className="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowSettleModal(false)}
                  className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-100"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 shadow-sm shadow-emerald-800/30"
                >
                  Record Settlement
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add Customer Modal */}
      {showAddCustomerModal && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="bg-white w-full max-w-md rounded-2xl shadow-2xl border border-slate-200 overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between">
              <div>
                <h3 className="font-bold text-slate-900 text-base">Add New Khata Customer</h3>
                <p className="text-xs text-slate-500">Register customer and set credit limit</p>
              </div>
              <button
                type="button"
                onClick={() => setShowAddCustomerModal(false)}
                className="text-slate-400 hover:text-slate-700"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleAddCustomer} className="p-6 space-y-4 text-xs">
              <div>
                <label className="font-bold text-slate-700 block mb-1">Customer Full Name *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Ramesh Hegde"
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 block mb-1">Mobile Phone (10-Digits) *</label>
                <input
                  type="tel"
                  required
                  placeholder="98800XXXXX"
                  value={newPhone}
                  onChange={(e) => setNewPhone(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none font-mono"
                />
              </div>

              <div>
                <label className="font-bold text-slate-700 block mb-1">Credit Limit (₹)</label>
                <input
                  type="number"
                  placeholder="5000"
                  value={newLimit}
                  onChange={(e) => setNewLimit(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none font-mono"
                />
              </div>

              <div className="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowAddCustomerModal(false)}
                  className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-100"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 shadow-sm shadow-emerald-800/30"
                >
                  Save Customer
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* History Modal */}
      {showHistoryModal && selectedCustomer && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="bg-white w-full max-w-lg rounded-2xl shadow-2xl border border-slate-200 overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between">
              <div>
                <h3 className="font-bold text-slate-900 text-base">{selectedCustomer.name} — Khata Statement</h3>
                <p className="text-xs text-slate-500">+91 {selectedCustomer.phone} • Credit Limit: {formatRupees(selectedCustomer.creditLimitPaise)}</p>
              </div>
              <button
                type="button"
                onClick={() => setShowHistoryModal(false)}
                className="text-slate-400 hover:text-slate-700"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-6 space-y-4 text-xs">
              <div className="flex justify-between items-center p-3 bg-slate-50 rounded-xl border border-slate-200">
                <span className="font-semibold text-slate-600">Current Outstanding Balance</span>
                <span className="font-bold font-mono text-rose-600 text-base">
                  {formatRupees(selectedCustomer.currentBalancePaise)}
                </span>
              </div>

              <div className="space-y-2">
                <p className="font-bold text-slate-700 text-xs">Recent Ledger Transactions</p>
                <div className="divide-y divide-slate-100 border border-slate-100 rounded-xl overflow-hidden bg-white">
                  <div className="p-3 flex justify-between items-center">
                    <div>
                      <p className="font-bold text-slate-900">Sale Bill: INV-2026-042</p>
                      <p className="text-[10px] text-slate-400">Today, 4:30 PM</p>
                    </div>
                    <span className="font-bold font-mono text-rose-600">+ ₹1,850.00</span>
                  </div>
                  <div className="p-3 flex justify-between items-center bg-slate-50/50">
                    <div>
                      <p className="font-bold text-slate-900">UPI Payment Settlement</p>
                      <p className="text-[10px] text-slate-400">Yesterday, 11:15 AM</p>
                    </div>
                    <span className="font-bold font-mono text-emerald-600">- ₹2,000.00</span>
                  </div>
                </div>
              </div>

              <div className="pt-3 border-t border-slate-100 flex justify-end">
                <button
                  type="button"
                  onClick={() => setShowHistoryModal(false)}
                  className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200"
                >
                  Close Statement
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
