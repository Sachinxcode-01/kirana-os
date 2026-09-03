"use client";

import React, { useState } from "react";
import Link from "next/link";
import { motion, type Variants } from "motion/react";
import { Sidebar } from "@/components/layout/Sidebar";
import { Header } from "@/components/layout/Header";
import {
  ShoppingCart,
  Users,
  Package,
  TrendingUp,
  AlertTriangle,
  ArrowUpRight,
  Plus,
  Send,
  Download,
  Sparkles,
  Truck,
  CheckCircle2,
  Barcode,
  Flame,
  ArrowRight,
  Clock,
  ShieldCheck,
  CreditCard,
  Banknote,
  Receipt,
  Activity,
  Keyboard,
  Printer,
} from "lucide-react";
import { QuickTenderModal } from "@/components/pos/QuickTenderModal";
import { KeyboardShortcutsModal } from "@/components/pos/KeyboardShortcutsModal";
import { ThermalReceiptModal } from "@/components/pos/ThermalReceiptModal";
import { useLanguage } from "@/contexts/LanguageContext";

export default function BackOfficeDashboard() {
  const { t } = useLanguage();
  const [filterMode, setFilterMode] = useState<"ALL" | "UPI" | "CASH" | "UDHAAR">("ALL");
  const [tenderOpen, setTenderOpen] = useState(false);
  const [selectedBillAmount, setSelectedBillAmount] = useState<number>(340);
  const [shortcutsOpen, setShortcutsOpen] = useState(false);
  const [receiptOpen, setReceiptOpen] = useState(false);
  const [selectedReceipt, setSelectedReceipt] = useState<any>(null);

  const kpis = [
    {
      title: t("kpi.revenue"),
      value: "₹24,500.00",
      change: `+14.2% ${t("kpi.vsYesterday")}`,
      icon: ShoppingCart,
      color: "emerald",
      bgGradient: "from-emerald-500/12 to-teal-500/5",
      borderColor: "border-emerald-200/90",
      pillBg: "bg-emerald-50 text-emerald-700 border-emerald-200",
    },
    {
      title: t("kpi.bills"),
      value: "42 Invoices",
      change: "Avg: ₹583.33 / bill",
      icon: Receipt,
      color: "teal",
      bgGradient: "from-teal-500/12 to-cyan-500/5",
      borderColor: "border-teal-200/90",
      pillBg: "bg-teal-50 text-teal-700 border-teal-200",
    },
    {
      title: t("kpi.udhaar"),
      value: "₹18,500.00",
      change: `4 ${t("kpi.dueToday")}`,
      icon: Users,
      color: "amber",
      bgGradient: "from-amber-500/12 to-orange-500/5",
      borderColor: "border-amber-200/90",
      pillBg: "bg-amber-50 text-amber-700 border-amber-200",
    },
    {
      title: t("kpi.skus"),
      value: "248 Products",
      change: `8 ${t("kpi.lowStockAlerts")}`,
      icon: Package,
      color: "indigo",
      bgGradient: "from-indigo-500/12 to-purple-500/5",
      borderColor: "border-indigo-200/90",
      pillBg: "bg-indigo-50 text-indigo-700 border-indigo-200",
    },
  ];

  const recentBills = [
    { id: "INV-2026-0042", time: "04:32 PM", customer: "Anil Sharma", amount: "₹1,850.00", mode: "Udhaar", status: "completed" },
    { id: "INV-2026-0041", time: "04:15 PM", customer: "Walk-in Retail", amount: "₹340.00", mode: "UPI QR", status: "completed" },
    { id: "INV-2026-0040", time: "03:50 PM", customer: "Sunita Patel", amount: "₹820.00", mode: "Cash", status: "completed" },
    { id: "INV-2026-0039", time: "03:20 PM", customer: "Walk-in Retail", amount: "₹120.00", mode: "Cash", status: "completed" },
  ];

  const filteredBills = recentBills.filter((b) => {
    if (filterMode === "UPI") return b.mode === "UPI QR";
    if (filterMode === "CASH") return b.mode === "Cash";
    if (filterMode === "UDHAAR") return b.mode === "Udhaar";
    return true;
  });

  const lowStockAlerts = [
    { name: "Amul Pasteurised Butter 500g", current: 7, min: 8, unit: "packet" },
    { name: "Brooke Bond Red Label Tea 500g", current: 3, min: 10, unit: "packet" },
    { name: "Aashirvaad Shudh Atta 10kg", current: 2, min: 5, unit: "packet" },
  ];

  const containerVariants: Variants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.08,
      },
    },
  };

  const itemVariants: Variants = {
    hidden: { opacity: 0, y: 15 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.35, ease: "easeOut" as const } },
  };

  return (
    <div className="flex min-h-screen bg-slate-50 relative overflow-hidden">
      {/* Aurora Ambient Lighting */}
      <div className="absolute top-0 right-0 w-[550px] h-[550px] bg-emerald-400/10 rounded-full blur-3xl pointer-events-none -mr-40 -mt-40"></div>
      <div className="absolute bottom-10 left-64 w-[400px] h-[400px] bg-teal-400/10 rounded-full blur-3xl pointer-events-none"></div>

      <QuickTenderModal
        isOpen={tenderOpen}
        onClose={() => setTenderOpen(false)}
        defaultBillAmount={selectedBillAmount}
      />
      <KeyboardShortcutsModal
        isOpen={shortcutsOpen}
        onClose={() => setShortcutsOpen(false)}
      />
      <ThermalReceiptModal
        isOpen={receiptOpen}
        onClose={() => setReceiptOpen(false)}
        invoiceData={selectedReceipt}
      />

      <Sidebar />

      <div className="flex-1 flex flex-col min-w-0 z-10">
        <Header
          title="Executive Store Dashboard"
          subtitle="Real-time live telemetry from POS counters & cloud database"
        />

        <main className="p-6 sm:p-8 space-y-6 flex-1 overflow-auto">
          {/* Quick Action Ribbon & Store Pulse */}
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex flex-wrap items-center justify-between gap-3 p-3.5 glass-card rounded-2xl shadow-xs"
          >
            <div className="flex flex-wrap items-center gap-2.5">
              <span className="text-xs font-bold text-slate-500 uppercase tracking-wider pl-2 pr-1 flex items-center gap-1.5">
                <Sparkles className="w-3.5 h-3.5 text-amber-500" /> {t("dash.quickActions")}:
              </span>
              <button
                type="button"
                onClick={() => {
                  setSelectedBillAmount(340);
                  setTenderOpen(true);
                }}
                className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-white bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 shadow-sm shadow-emerald-950/20 transition-all hover:scale-102 cursor-pointer"
              >
                <Banknote className="w-3.5 h-3.5" />
                <span>{t("header.quickTender")}</span>
                <kbd className="px-1.5 py-0.2 rounded text-[10px] font-mono font-bold bg-white/20 text-white">
                  F4
                </kbd>
              </button>
              <Link
                href="/catalog"
                className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-slate-700 bg-white hover:bg-slate-50 border border-slate-200/90 shadow-xs transition-all hover:scale-102"
              >
                <Plus className="w-3.5 h-3.5 text-emerald-600" />
                <span>{t("dash.addSku")}</span>
                <kbd className="px-1.5 py-0.2 rounded text-[10px] font-mono font-bold bg-slate-100 text-slate-500 border border-slate-200">
                  F1
                </kbd>
              </Link>
              <button
                type="button"
                onClick={() => setShortcutsOpen(true)}
                className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-slate-700 bg-white hover:bg-slate-50 border border-slate-200/90 shadow-xs transition-all hover:scale-102 cursor-pointer"
              >
                <Keyboard className="w-3.5 h-3.5 text-teal-600" />
                <span>{t("header.shortcuts")}</span>
                <kbd className="px-1.5 py-0.2 rounded text-[10px] font-mono font-bold bg-slate-100 text-slate-500 border border-slate-200">
                  ?
                </kbd>
              </button>
              <Link
                href="/udhaar"
                className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-slate-700 bg-white hover:bg-slate-50 border border-slate-200/90 shadow-xs transition-all hover:scale-102"
              >
                <Send className="w-3.5 h-3.5 text-emerald-600" /> {t("dash.sendKhataReminder")}
              </Link>
              <Link
                href="/purchases"
                className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-slate-700 bg-white hover:bg-slate-50 border border-slate-200/90 shadow-xs transition-all hover:scale-102"
              >
                <Truck className="w-3.5 h-3.5 text-teal-600" /> {t("dash.replenishPo")}
              </Link>
              <Link
                href="/gst"
                className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-slate-700 bg-white hover:bg-slate-50 border border-slate-200/90 shadow-xs transition-all hover:scale-102"
              >
                <Download className="w-3.5 h-3.5 text-slate-500" /> {t("dash.exportGst")}
              </Link>
            </div>

            {/* Quick Live Pulse Badge */}
            <div className="hidden xl:flex items-center gap-2 px-3 py-1 bg-emerald-50 text-emerald-800 text-xs font-bold rounded-xl border border-emerald-200">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
              </span>
              <span>{t("dash.cloudOnline")}</span>
            </div>
          </motion.div>

          {/* Top KPI Grid */}
          <motion.div
            variants={containerVariants}
            initial="hidden"
            animate="visible"
            className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4"
          >
            {kpis.map((kpi) => {
              const Icon = kpi.icon;
              return (
                <motion.div
                  key={kpi.title}
                  variants={itemVariants}
                  whileHover={{ y: -4, transition: { duration: 0.2 } }}
                  className={`p-5 glass-card rounded-2xl relative overflow-hidden shadow-xs hover:shadow-md transition-all group border ${kpi.borderColor}`}
                >
                  <div className={`absolute top-0 right-0 w-28 h-28 bg-gradient-to-br ${kpi.bgGradient} rounded-full blur-xl -mr-6 -mt-6 pointer-events-none`}></div>
                  <div className="flex items-center justify-between">
                    <span className="text-xs text-slate-500 font-bold uppercase tracking-wider">{kpi.title}</span>
                    <div className="p-2.5 bg-slate-100 rounded-xl text-slate-700 group-hover:bg-emerald-50 group-hover:text-emerald-700 transition-colors">
                      <Icon className="w-4 h-4" />
                    </div>
                  </div>
                  <h3 className="text-3xl font-black font-mono mt-3 text-slate-900 tracking-tight">{kpi.value}</h3>
                  <div className="flex items-center gap-1.5 mt-2.5">
                    <span className={`inline-flex items-center gap-1 text-[11px] font-bold px-2 py-0.5 rounded-md border ${kpi.pillBg}`}>
                      <ArrowUpRight className="w-3 h-3" /> {kpi.change}
                    </span>
                  </div>
                </motion.div>
              );
            })}
          </motion.div>

          {/* Activity Feeds & Stockout Warnings */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Live POS Sales Stream */}
            <motion.div
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.2 }}
              className="lg:col-span-2 p-6 glass-card rounded-2xl shadow-xs space-y-5"
            >
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <h4 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                    <ShoppingCart className="w-4 h-4 text-emerald-600" /> {t("stream.title")}
                  </h4>
                  <p className="text-xs text-slate-500 mt-0.5">{t("stream.subtitle")}</p>
                </div>

                {/* Filter Pills */}
                <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-xl text-[11px] font-bold">
                  {(["ALL", "UPI", "CASH", "UDHAAR"] as const).map((m) => (
                    <button
                      key={m}
                      type="button"
                      onClick={() => setFilterMode(m)}
                      className={`px-2.5 py-1 rounded-lg transition-all cursor-pointer ${
                        filterMode === m
                          ? "bg-white text-emerald-700 shadow-xs border border-slate-200 font-bold"
                          : "text-slate-500 hover:text-slate-900"
                      }`}
                    >
                      {m === "ALL" ? t("filter.all") : m === "UPI" ? t("filter.upi") : m === "CASH" ? t("filter.cash") : t("filter.udhaar")}
                    </button>
                  ))}
                </div>
              </div>

              {/* Transactions Table */}
              <div className="overflow-x-auto rounded-xl border border-slate-200/90 shadow-xs">
                <table className="w-full text-left text-xs border-collapse">
                  <thead>
                    <tr className="bg-slate-100/90 border-b border-slate-200 text-[11px] font-bold text-slate-600 uppercase">
                      <th className="py-3 px-3.5">{t("stream.billNumber")}</th>
                      <th className="py-3 px-3.5">{t("stream.time")}</th>
                      <th className="py-3 px-3.5">{t("stream.customer")}</th>
                      <th className="py-3 px-3.5 text-right">{t("stream.amount")}</th>
                      <th className="py-3 px-3.5 text-center">{t("stream.paymentMode")}</th>
                      <th className="py-3 px-3.5 text-right">{t("stream.quickTender")}</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 font-medium">
                    {filteredBills.map((b) => (
                      <tr key={b.id} className="hover:bg-slate-50/80 transition-colors">
                        <td className="py-3 px-3.5 font-mono font-bold text-slate-900">{b.id}</td>
                        <td className="py-3 px-3.5 text-slate-500 font-mono text-[11px]">{b.time}</td>
                        <td className="py-3 px-3.5 text-slate-800 font-semibold">{b.customer}</td>
                        <td className="py-3 px-3.5 text-right font-mono font-bold text-slate-900">{b.amount}</td>
                        <td className="py-3 px-3.5 text-center">
                          <span
                            className={`px-2.5 py-1 rounded-full text-[10px] font-bold border ${
                              b.mode === "UPI QR"
                                ? "bg-teal-50 text-teal-700 border-teal-200"
                                : b.mode === "Udhaar"
                                ? "bg-amber-50 text-amber-700 border-amber-200"
                                : "bg-slate-100 text-slate-700 border-slate-200"
                            }`}
                          >
                            {b.mode}
                          </span>
                        </td>
                        <td className="py-3 px-3.5 text-right">
                          <div className="flex items-center justify-end gap-1.5">
                            <button
                              type="button"
                              onClick={() => {
                                const parsed = parseFloat(b.amount.replace(/[^0-9.]/g, "")) || 340;
                                setSelectedReceipt({
                                  invoiceNumber: b.id,
                                  dateStr: `${b.time}, Today`,
                                  customerName: b.customer,
                                  paymentMode: b.mode,
                                  totalPaise: Math.round(parsed * 100),
                                });
                                setReceiptOpen(true);
                              }}
                              className="p-1.5 text-slate-400 hover:text-emerald-600 rounded-lg hover:bg-emerald-50 transition-colors cursor-pointer"
                              title="Print Thermal 58mm/80mm Receipt (F8)"
                            >
                              <Printer className="w-3.5 h-3.5" />
                            </button>
                            <button
                              type="button"
                              onClick={() => {
                                const parsed = parseFloat(b.amount.replace(/[^0-9.]/g, "")) || 340;
                                setSelectedBillAmount(parsed);
                                setTenderOpen(true);
                              }}
                              className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-[11px] font-bold text-emerald-700 bg-emerald-50 hover:bg-emerald-100 border border-emerald-200 transition-colors cursor-pointer"
                              title={t("stream.settle")}
                            >
                              <Banknote className="w-3 h-3" />
                              <span>{t("stream.settle")}</span>
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Settlement Summary Pill Bar */}
              <div className="p-3 bg-slate-50 rounded-xl border border-slate-200/80 flex flex-wrap items-center justify-between gap-3 text-xs">
                <span className="font-semibold text-slate-500 flex items-center gap-1.5">
                  <Activity className="w-3.5 h-3.5 text-emerald-600" /> Settlement Split:
                </span>
                <div className="flex items-center gap-4 text-[11px] font-mono font-bold">
                  <span className="text-teal-700">UPI: 54% (₹13,230)</span>
                  <span className="text-slate-700">Cash: 31% (₹7,595)</span>
                  <span className="text-amber-700">Khata: 15% (₹3,675)</span>
                </div>
                <Link
                  href="/analytics"
                  className="text-xs font-bold text-emerald-700 hover:text-emerald-800 flex items-center gap-1"
                >
                  Full Analytics &rarr;
                </Link>
              </div>
            </motion.div>

            {/* Critical Low Stock Column with Visual Threshold Meter */}
            <motion.div
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.3 }}
              className="p-6 glass-card rounded-2xl shadow-xs space-y-5"
            >
              <div className="flex items-center justify-between">
                <h4 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <AlertTriangle className="w-4 h-4 text-amber-500" /> Stockout Risk Warnings
                </h4>
                <Link href="/catalog" className="text-[11px] font-bold text-emerald-700 hover:underline">
                  Catalog &rarr;
                </Link>
              </div>

              <div className="space-y-3 text-xs">
                {lowStockAlerts.map((item) => {
                  const stockPct = Math.min(100, Math.round((item.current / item.min) * 100));
                  const isSevere = stockPct <= 50;

                  return (
                    <motion.div
                      whileHover={{ scale: 1.01 }}
                      key={item.name}
                      className="p-3.5 bg-amber-50/60 rounded-xl border border-amber-200/90 space-y-2 shadow-xs"
                    >
                      <div className="flex justify-between items-start gap-2">
                        <p className="font-bold text-slate-900 leading-tight">{item.name}</p>
                        <span
                          className={`text-[10px] font-bold px-2 py-0.5 rounded border shrink-0 ${
                            isSevere
                              ? "bg-rose-50 text-rose-600 border-rose-200"
                              : "bg-amber-100 text-amber-800 border-amber-300"
                          }`}
                        >
                          {stockPct}% Safe
                        </span>
                      </div>

                      {/* Stock Visual Progress Bar */}
                      <div className="w-full bg-slate-200/80 h-1.5 rounded-full overflow-hidden">
                        <div
                          className={`h-full rounded-full transition-all ${
                            isSevere ? "bg-rose-500" : "bg-amber-500"
                          }`}
                          style={{ width: `${stockPct}%` }}
                        />
                      </div>

                      <div className="flex justify-between items-center text-[11px] text-slate-600 font-semibold pt-0.5">
                        <span>
                          Current: <strong className="font-mono text-slate-900">{item.current}</strong> {item.unit}
                        </span>
                        <span className="text-slate-500 font-medium">
                          Min: <strong className="font-mono text-slate-800">{item.min}</strong> {item.unit}
                        </span>
                      </div>
                    </motion.div>
                  );
                })}

                <Link
                  href="/purchases"
                  className="w-full flex items-center justify-center gap-1.5 py-2.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold shadow-md shadow-slate-950/20 transition-all mt-2 cursor-pointer"
                >
                  <Truck className="w-3.5 h-3.5 text-emerald-400" /> Order Replenishment
                </Link>
              </div>
            </motion.div>
          </div>
        </main>
      </div>
    </div>
  );
}
