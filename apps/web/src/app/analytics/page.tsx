"use client";

import React, { useState } from "react";
import { motion, AnimatePresence, type Variants } from "motion/react";
import { Sidebar } from "@/components/layout/Sidebar";
import { Header } from "@/components/layout/Header";
import {
  TrendingUp,
  DollarSign,
  ShoppingCart,
  Percent,
  Clock,
  AlertCircle,
  FileCheck2,
  PieChart,
  Calendar,
  Download,
  ArrowUpRight,
  ShieldCheck,
  PackageX,
  Printer,
  Sparkles,
  ChevronRight,
  Filter,
  CheckCircle2,
  Share2,
  Layers,
  BarChart3,
  Flame,
} from "lucide-react";
import { DayEndZReport } from "@/types";

const SAMPLE_Z_REPORTS: DayEndZReport[] = [
  {
    shiftId: "s1",
    registerName: "Main Counter 1",
    cashierName: "Ramesh Kumar (Owner)",
    openedAt: "Today, 08:30 AM",
    closedAt: "Pending (Active Live Shift)",
    openingCashPaise: 200000,
    actualCashPaise: 1675000,
    expectedCashPaise: 1675000,
    variancePaise: 0,
    grossSalesPaise: 2450000,
    cashSalesPaise: 1475000,
    upiSalesPaise: 825000,
    creditSalesPaise: 150000,
    billsCount: 42,
    isBalanced: true,
  },
  {
    shiftId: "s2",
    registerName: "Main Counter 1",
    cashierName: "Suresh (Staff)",
    openedAt: "Yesterday, 08:30 AM",
    closedAt: "Yesterday, 10:15 PM",
    openingCashPaise: 200000,
    actualCashPaise: 2840000,
    expectedCashPaise: 2840000,
    variancePaise: 0,
    grossSalesPaise: 4280000,
    cashSalesPaise: 2640000,
    upiSalesPaise: 1420000,
    creditSalesPaise: 220000,
    billsCount: 88,
    isBalanced: true,
  },
];

const DEAD_STOCK_ITEMS = [
  { name: "Patanjali Honey 500g", currentStock: 18, costPaise: 16000, tiedCapitalPaise: 288000, unmovedDays: 72, risk: "high" },
  { name: "Dabur Red Toothpaste 300g", currentStock: 24, costPaise: 9500, tiedCapitalPaise: 228000, unmovedDays: 65, risk: "medium" },
  { name: "Everest Sambhar Masala 100g", currentStock: 30, costPaise: 4200, tiedCapitalPaise: 126000, unmovedDays: 60, risk: "medium" },
];

const HOURLY_VELOCITY = [
  { hour: "8 AM", count: 2, height: "18%", revenue: "₹680" },
  { hour: "10 AM", count: 6, height: "42%", revenue: "₹2,420" },
  { hour: "12 PM", count: 5, height: "35%", revenue: "₹1,950" },
  { hour: "2 PM", count: 3, height: "22%", revenue: "₹1,120" },
  { hour: "4 PM", count: 7, height: "50%", revenue: "₹3,400" },
  { hour: "6 PM", count: 14, height: "92%", revenue: "₹7,200", peak: true },
  { hour: "8 PM", count: 16, height: "100%", revenue: "₹8,450", peak: true },
  { hour: "10 PM", count: 4, height: "30%", revenue: "₹1,680" },
];

export default function AnalyticsPage() {
  const [activeTab, setActiveTab] = useState<"overview" | "zreport" | "deadstock" | "rush">("overview");
  const [timeRange, setTimeRange] = useState("Today");
  const [downloadSuccess, setDownloadSuccess] = useState(false);

  const formatRupees = (paise: number) => `₹${(paise / 100).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

  const handleExport = () => {
    setDownloadSuccess(true);
    setTimeout(() => setDownloadSuccess(false), 2500);
  };

  const containerVariants: Variants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.08,
      },
    },
  };

  const cardVariants: Variants = {
    hidden: { opacity: 0, y: 16 },
    visible: { opacity: 1, y: 0, transition: { duration: 0.4, ease: "easeOut" as const } },
  };

  return (
    <div className="flex min-h-screen bg-slate-50 relative overflow-hidden">
      {/* Background Aurora Ambient Mesh */}
      <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-emerald-300/15 rounded-full blur-3xl pointer-events-none -mr-40 -mt-40"></div>
      <div className="absolute bottom-0 left-64 w-[450px] h-[450px] bg-teal-300/10 rounded-full blur-3xl pointer-events-none"></div>

      <Sidebar />

      <div className="flex-1 flex flex-col min-w-0 z-10">
        <Header
          title="Executive Analytics & Intelligence"
          subtitle="Real-time financial telemetry, cash drawer reconciliation, and margin performance"
        />

        <main className="p-8 space-y-6 flex-1 overflow-auto">
          {/* Top Controls Bar */}
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            {/* Tabs */}
            <div className="flex items-center p-1 bg-slate-200/70 backdrop-blur-md rounded-2xl border border-slate-200 shadow-inner">
              {[
                { id: "overview", label: "Executive Overview", icon: BarChart3 },
                { id: "zreport", label: "Day-End Z-Report", icon: FileCheck2 },
                { id: "deadstock", label: "Dead Stock Audit", icon: PackageX },
                { id: "rush", label: "Rush Heatmap", icon: Flame },
              ].map((tab) => {
                const Icon = tab.icon;
                const isActive = activeTab === tab.id;
                return (
                  <button
                    key={tab.id}
                    onClick={() => setActiveTab(tab.id as any)}
                    className={`relative flex items-center gap-2 px-3.5 py-1.5 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
                      isActive ? "text-slate-900 shadow-xs" : "text-slate-600 hover:text-slate-900"
                    }`}
                  >
                    {isActive && (
                      <motion.div
                        layoutId="activeAnalyticsTab"
                        transition={{ type: "spring", stiffness: 400, damping: 32 }}
                        className="absolute inset-0 bg-white rounded-xl shadow-sm border border-slate-200/80"
                      />
                    )}
                    <span className="relative z-10 flex items-center gap-1.5">
                      <Icon className={`w-3.5 h-3.5 ${isActive ? "text-emerald-600" : "text-slate-500"}`} />
                      {tab.label}
                    </span>
                  </button>
                );
              })}
            </div>

            {/* Range & Actions */}
            <div className="flex items-center gap-2.5">
              <div className="flex items-center bg-white rounded-xl border border-slate-200/80 px-3 py-1.5 shadow-xs text-xs font-semibold text-slate-700">
                <Calendar className="w-3.5 h-3.5 text-slate-400 mr-2" />
                <select
                  value={timeRange}
                  onChange={(e) => setTimeRange(e.target.value)}
                  className="bg-transparent focus:outline-none cursor-pointer text-slate-800"
                >
                  <option value="Today">Today (Live)</option>
                  <option value="Yesterday">Yesterday</option>
                  <option value="Last 7 Days">Last 7 Days</option>
                  <option value="This Month">This Month (GSTR-1 Period)</option>
                </select>
              </div>

              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={handleExport}
                className="flex items-center gap-2 px-3.5 py-1.5 bg-white hover:bg-slate-50 text-slate-700 rounded-xl border border-slate-200/80 text-xs font-semibold shadow-xs cursor-pointer"
              >
                {downloadSuccess ? (
                  <>
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                    <span className="text-emerald-700">Downloaded</span>
                  </>
                ) : (
                  <>
                    <Download className="w-3.5 h-3.5 text-slate-500" />
                    <span>Export CSV</span>
                  </>
                )}
              </motion.button>
            </div>
          </div>

          <AnimatePresence mode="wait">
            {activeTab === "overview" && (
              <motion.div
                key="overview"
                variants={containerVariants}
                initial="hidden"
                animate="visible"
                exit={{ opacity: 0, y: -10 }}
                className="space-y-6"
              >
                {/* 4 Animated KPI Cards */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                  {/* Card 1: Gross Revenue */}
                  <motion.div
                    variants={cardVariants}
                    whileHover={{ y: -4, transition: { duration: 0.2 } }}
                    className="p-5 glass-card rounded-2xl relative overflow-hidden shadow-xs hover:shadow-md transition-shadow group"
                  >
                    <div className="absolute top-0 right-0 w-24 h-24 bg-emerald-500/10 rounded-full blur-xl -mr-6 -mt-6 group-hover:bg-emerald-500/20 transition-colors"></div>
                    <div className="flex items-center justify-between">
                      <span className="text-xs text-slate-500 font-bold uppercase tracking-wider">Gross Revenue (Today)</span>
                      <div className="p-2.5 bg-emerald-50 text-emerald-600 rounded-xl border border-emerald-100">
                        <DollarSign className="w-4 h-4" />
                      </div>
                    </div>
                    <h3 className="text-3xl font-black font-mono mt-3 text-slate-900 tracking-tight">₹24,500.00</h3>
                    <div className="flex items-center gap-1.5 mt-2.5 text-xs text-emerald-700 font-bold">
                      <span className="flex items-center px-1.5 py-0.5 rounded-md bg-emerald-100/70 border border-emerald-200">
                        <ArrowUpRight className="w-3 h-3 mr-0.5" /> +14.2%
                      </span>
                      <span className="text-slate-500 font-medium">vs ₹21,450 yesterday</span>
                    </div>
                  </motion.div>

                  {/* Card 2: Gross Profit */}
                  <motion.div
                    variants={cardVariants}
                    whileHover={{ y: -4, transition: { duration: 0.2 } }}
                    className="p-5 glass-card rounded-2xl relative overflow-hidden shadow-xs hover:shadow-md transition-shadow group"
                  >
                    <div className="absolute top-0 right-0 w-24 h-24 bg-teal-500/10 rounded-full blur-xl -mr-6 -mt-6 group-hover:bg-teal-500/20 transition-colors"></div>
                    <div className="flex items-center justify-between">
                      <span className="text-xs text-slate-500 font-bold uppercase tracking-wider">Est. Gross Margin</span>
                      <div className="p-2.5 bg-teal-50 text-teal-600 rounded-xl border border-teal-100">
                        <Percent className="w-4 h-4" />
                      </div>
                    </div>
                    <h3 className="text-3xl font-black font-mono mt-3 text-slate-900 tracking-tight">₹5,240.00</h3>
                    <div className="flex items-center gap-2 mt-2.5 text-xs">
                      <span className="px-2 py-0.5 rounded-md bg-teal-100/70 text-teal-800 font-bold border border-teal-200">
                        21.4% Margin
                      </span>
                      <span className="text-slate-500 font-medium">healthy FMCG tier</span>
                    </div>
                  </motion.div>

                  {/* Card 3: Finalized Invoices */}
                  <motion.div
                    variants={cardVariants}
                    whileHover={{ y: -4, transition: { duration: 0.2 } }}
                    className="p-5 glass-card rounded-2xl relative overflow-hidden shadow-xs hover:shadow-md transition-shadow group"
                  >
                    <div className="absolute top-0 right-0 w-24 h-24 bg-indigo-500/10 rounded-full blur-xl -mr-6 -mt-6 group-hover:bg-indigo-500/20 transition-colors"></div>
                    <div className="flex items-center justify-between">
                      <span className="text-xs text-slate-500 font-bold uppercase tracking-wider">Finalized Invoices</span>
                      <div className="p-2.5 bg-indigo-50 text-indigo-600 rounded-xl border border-indigo-100">
                        <ShoppingCart className="w-4 h-4" />
                      </div>
                    </div>
                    <h3 className="text-3xl font-black font-mono mt-3 text-slate-900 tracking-tight">42 Bills</h3>
                    <div className="flex items-center gap-1.5 mt-2.5 text-xs text-slate-600">
                      <span className="font-bold text-slate-900 font-mono">₹583.33</span>
                      <span className="text-slate-500">avg basket size</span>
                    </div>
                  </motion.div>

                  {/* Card 4: Drawer Status */}
                  <motion.div
                    variants={cardVariants}
                    whileHover={{ y: -4, transition: { duration: 0.2 } }}
                    className="p-5 glass-card rounded-2xl relative overflow-hidden shadow-xs hover:shadow-md transition-shadow group"
                  >
                    <div className="absolute top-0 right-0 w-24 h-24 bg-emerald-500/10 rounded-full blur-xl -mr-6 -mt-6 group-hover:bg-emerald-500/20 transition-colors"></div>
                    <div className="flex items-center justify-between">
                      <span className="text-xs text-slate-500 font-bold uppercase tracking-wider">Cash Drawer Audit</span>
                      <div className="p-2.5 bg-emerald-50 text-emerald-600 rounded-xl border border-emerald-100">
                        <ShieldCheck className="w-4 h-4" />
                      </div>
                    </div>
                    <h3 className="text-3xl font-black font-mono mt-3 text-emerald-600 tracking-tight">100% Balanced</h3>
                    <div className="flex items-center gap-1.5 mt-2.5 text-xs text-emerald-700 font-semibold">
                      <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
                      <span>₹0.00 Variance on live shift</span>
                    </div>
                  </motion.div>
                </div>

                {/* Middle Grid: Payment Breakdown & Hourly Rush Velocity */}
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                  {/* Payment Breakdown Card */}
                  <motion.div
                    variants={cardVariants}
                    className="p-6 glass-card rounded-2xl shadow-xs space-y-5"
                  >
                    <div className="flex items-center justify-between">
                      <h4 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                        <PieChart className="w-4 h-4 text-emerald-600" /> Payment Split Analysis
                      </h4>
                      <span className="text-[11px] font-bold text-slate-500 bg-slate-100 px-2 py-0.5 rounded-md">
                        42 Total
                      </span>
                    </div>

                    <div className="space-y-4 text-xs">
                      <div>
                        <div className="flex justify-between font-semibold text-slate-700 mb-1.5">
                          <span className="flex items-center gap-1.5">
                            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500"></span> Physical Cash
                          </span>
                          <span className="font-mono font-bold text-slate-900">₹14,750.00 (60.2%)</span>
                        </div>
                        <div className="w-full bg-slate-100 h-3 rounded-full overflow-hidden p-0.5 border border-slate-200/50">
                          <motion.div
                            initial={{ width: 0 }}
                            animate={{ width: "60.2%" }}
                            transition={{ duration: 0.8, ease: "easeOut" }}
                            className="bg-gradient-to-r from-emerald-500 to-teal-500 h-full rounded-full"
                          />
                        </div>
                      </div>

                      <div>
                        <div className="flex justify-between font-semibold text-slate-700 mb-1.5">
                          <span className="flex items-center gap-1.5">
                            <span className="w-2.5 h-2.5 rounded-full bg-teal-500"></span> UPI / Bharat QR
                          </span>
                          <span className="font-mono font-bold text-slate-900">₹8,250.00 (33.7%)</span>
                        </div>
                        <div className="w-full bg-slate-100 h-3 rounded-full overflow-hidden p-0.5 border border-slate-200/50">
                          <motion.div
                            initial={{ width: 0 }}
                            animate={{ width: "33.7%" }}
                            transition={{ duration: 0.8, delay: 0.1, ease: "easeOut" }}
                            className="bg-gradient-to-r from-teal-500 to-cyan-500 h-full rounded-full"
                          />
                        </div>
                      </div>

                      <div>
                        <div className="flex justify-between font-semibold text-slate-700 mb-1.5">
                          <span className="flex items-center gap-1.5">
                            <span className="w-2.5 h-2.5 rounded-full bg-amber-500"></span> Udhaar (Khata Ledger)
                          </span>
                          <span className="font-mono font-bold text-slate-900">₹1,500.00 (6.1%)</span>
                        </div>
                        <div className="w-full bg-slate-100 h-3 rounded-full overflow-hidden p-0.5 border border-slate-200/50">
                          <motion.div
                            initial={{ width: 0 }}
                            animate={{ width: "6.1%" }}
                            transition={{ duration: 0.8, delay: 0.2, ease: "easeOut" }}
                            className="bg-gradient-to-r from-amber-500 to-orange-500 h-full rounded-full"
                          />
                        </div>
                      </div>
                    </div>

                    <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-[11px] text-slate-500">
                      <span>UPI vs Cash Ratio: 1:1.78</span>
                      <span className="text-emerald-700 font-semibold flex items-center gap-1">
                        <Sparkles className="w-3 h-3 text-amber-500" /> 0% Gateway MDR
                      </span>
                    </div>
                  </motion.div>

                  {/* Hourly Velocity Card */}
                  <motion.div
                    variants={cardVariants}
                    className="lg:col-span-2 p-6 glass-card rounded-2xl shadow-xs space-y-5"
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <h4 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                          <Clock className="w-4 h-4 text-emerald-600" /> Hourly Billing Velocity (Peak Windows)
                        </h4>
                        <p className="text-xs text-slate-500 mt-0.5">Counter activity timeline and revenue velocity</p>
                      </div>
                      <span className="text-[11px] font-bold text-emerald-800 px-3 py-1 bg-emerald-50 rounded-xl border border-emerald-200 flex items-center gap-1.5 shadow-xs">
                        <Flame className="w-3.5 h-3.5 text-amber-500" />
                        Peak Rush: 6:00 PM – 9:00 PM
                      </span>
                    </div>

                    {/* Animated Bar Graph */}
                    <div className="grid grid-cols-8 gap-3 items-end h-40 pt-4 border-b border-slate-100 pb-2">
                      {HOURLY_VELOCITY.map((item, index) => (
                        <div key={item.hour} className="flex flex-col items-center gap-2 h-full justify-end group cursor-pointer">
                          <span className="text-[10px] font-mono font-bold text-slate-600 opacity-0 group-hover:opacity-100 transition-opacity">
                            {item.revenue}
                          </span>
                          <motion.div
                            initial={{ height: 0 }}
                            animate={{ height: item.height }}
                            transition={{ duration: 0.6, delay: index * 0.05, ease: "easeOut" }}
                            className={`w-full rounded-xl transition-all shadow-xs group-hover:scale-105 ${
                              item.peak
                                ? "bg-gradient-to-t from-emerald-600 to-teal-400 shadow-emerald-600/30"
                                : "bg-slate-200 hover:bg-slate-300"
                            }`}
                            title={`${item.count} bills finalized (${item.revenue})`}
                          />
                          <span className={`text-[11px] font-bold ${item.peak ? "text-emerald-700" : "text-slate-500"}`}>
                            {item.hour}
                          </span>
                        </div>
                      ))}
                    </div>

                    <div className="flex items-center justify-between text-xs text-slate-500 pt-1">
                      <div className="flex items-center gap-4">
                        <span className="flex items-center gap-1.5">
                          <span className="w-2.5 h-2.5 rounded-md bg-emerald-600"></span> Peak Counter Rush Hours
                        </span>
                        <span className="flex items-center gap-1.5">
                          <span className="w-2.5 h-2.5 rounded-md bg-slate-300"></span> Standard Hours
                        </span>
                      </div>
                      <span className="font-semibold text-slate-700">Total Billed: ₹24,500.00</span>
                    </div>
                  </motion.div>
                </div>

                {/* Dead Stock Mini Banner */}
                <motion.div
                  variants={cardVariants}
                  className="p-5 bg-gradient-to-r from-rose-50/80 via-white to-amber-50/60 rounded-2xl border border-rose-200/80 shadow-xs flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4"
                >
                  <div className="flex items-center gap-3.5">
                    <div className="p-3 bg-rose-100/80 text-rose-700 rounded-xl border border-rose-200">
                      <PackageX className="w-5 h-5" />
                    </div>
                    <div>
                      <h4 className="font-bold text-slate-900 text-sm">3 Products Identified in Dead Stock Liquidation Audit</h4>
                      <p className="text-xs text-slate-600 mt-0.5">
                        ₹6,420.00 in capital is locked in inventory that hasn't sold for over 60+ days.
                      </p>
                    </div>
                  </div>
                  <button
                    onClick={() => setActiveTab("deadstock")}
                    className="flex items-center gap-1.5 px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-xl text-xs font-bold shadow-md shadow-rose-950/20 transition-all cursor-pointer whitespace-nowrap"
                  >
                    <span>View Dead Stock Audit</span>
                    <ChevronRight className="w-3.5 h-3.5" />
                  </button>
                </motion.div>
              </motion.div>
            )}

            {/* Tab 2: Day-End Z-Report */}
            {activeTab === "zreport" && (
              <motion.div
                key="zreport"
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -12 }}
                className="space-y-6"
              >
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  {SAMPLE_Z_REPORTS.map((report) => (
                    <div
                      key={report.shiftId}
                      className="p-6 glass-card rounded-2xl border border-slate-200 shadow-sm space-y-5 relative overflow-hidden"
                    >
                      <div className="flex items-start justify-between">
                        <div>
                          <div className="flex items-center gap-2">
                            <h4 className="font-bold text-slate-900 text-base">{report.registerName}</h4>
                            <span
                              className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${
                                report.isBalanced
                                  ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                                  : "bg-rose-50 text-rose-700 border-rose-200"
                              }`}
                            >
                              {report.isBalanced ? "Balanced (₹0.00)" : "Variance Detected"}
                            </span>
                          </div>
                          <p className="text-xs text-slate-500 mt-0.5">Cashier: {report.cashierName}</p>
                        </div>

                        <button
                          type="button"
                          onClick={() => alert(`Printing Z-Report for ${report.registerName}`)}
                          className="flex items-center gap-1 px-3 py-1.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-semibold transition-colors cursor-pointer"
                        >
                          <Printer className="w-3.5 h-3.5" />
                          <span>Print Z-Report</span>
                        </button>
                      </div>

                      {/* Financial Breakdown Table */}
                      <div className="p-4 bg-slate-50 rounded-xl border border-slate-200/80 space-y-2 text-xs font-mono">
                        <div className="flex justify-between py-1 border-b border-slate-200/60">
                          <span className="text-slate-600 font-sans">Gross Day Sales:</span>
                          <span className="font-bold text-slate-900">{formatRupees(report.grossSalesPaise)}</span>
                        </div>
                        <div className="flex justify-between py-1 border-b border-slate-200/60">
                          <span className="text-slate-600 font-sans">1. Cash Inflow:</span>
                          <span className="text-emerald-700 font-bold">{formatRupees(report.cashSalesPaise)}</span>
                        </div>
                        <div className="flex justify-between py-1 border-b border-slate-200/60">
                          <span className="text-slate-600 font-sans">2. Digital UPI Payments:</span>
                          <span className="text-teal-700 font-bold">{formatRupees(report.upiSalesPaise)}</span>
                        </div>
                        <div className="flex justify-between py-1 border-b border-slate-200/60">
                          <span className="text-slate-600 font-sans">3. Khata (Credit Issued):</span>
                          <span className="text-amber-700 font-bold">{formatRupees(report.creditSalesPaise)}</span>
                        </div>
                        <div className="flex justify-between py-1 pt-2 font-bold text-sm">
                          <span className="text-slate-900 font-sans">Expected In Drawer:</span>
                          <span className="text-slate-900 font-black">{formatRupees(report.expectedCashPaise)}</span>
                        </div>
                        <div className="flex justify-between py-1 text-sm font-bold text-emerald-600">
                          <span className="text-slate-700 font-sans">Actual Cash Counted:</span>
                          <span className="font-black">{formatRupees(report.actualCashPaise)}</span>
                        </div>
                      </div>

                      {/* Timestamps */}
                      <div className="flex items-center justify-between text-[11px] text-slate-500 pt-1">
                        <span>Shift Opened: {report.openedAt}</span>
                        <span>{report.closedAt}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </motion.div>
            )}

            {/* Tab 3: Dead Stock Audit */}
            {activeTab === "deadstock" && (
              <motion.div
                key="deadstock"
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -12 }}
                className="p-6 glass-card rounded-2xl border border-slate-200 shadow-sm space-y-4"
              >
                <div className="flex items-center justify-between">
                  <div>
                    <h4 className="font-bold text-slate-900 text-base flex items-center gap-2">
                      <PackageX className="w-5 h-5 text-rose-600" /> Slow-Moving & Dead Stock Liquidation Matrix
                    </h4>
                    <p className="text-xs text-slate-500 mt-0.5">
                      Items sitting unmoved for &gt;60 days with cost capital locked in shelf storage
                    </p>
                  </div>
                  <div className="px-3.5 py-1.5 bg-rose-50 border border-rose-200 rounded-xl text-xs font-bold text-rose-700 font-mono">
                    Total Locked Capital: ₹6,420.00
                  </div>
                </div>

                <div className="overflow-x-auto rounded-xl border border-slate-200">
                  <table className="w-full text-left text-xs border-collapse">
                    <thead>
                      <tr className="bg-slate-100 text-[11px] font-bold text-slate-700 uppercase">
                        <th className="py-3 px-4">Product Name</th>
                        <th className="py-3 px-4 text-center">Unsold Units</th>
                        <th className="py-3 px-4 text-right">Unit Cost</th>
                        <th className="py-3 px-4 text-right">Locked Capital</th>
                        <th className="py-3 px-4 text-center">Shelf Idle Days</th>
                        <th className="py-3 px-4 text-center">Action Plan</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 font-medium">
                      {DEAD_STOCK_ITEMS.map((item) => (
                        <tr key={item.name} className="hover:bg-slate-50/60 transition-colors">
                          <td className="py-3 px-4 font-bold text-slate-900">{item.name}</td>
                          <td className="py-3 px-4 text-center font-semibold">{item.currentStock} units</td>
                          <td className="py-3 px-4 text-right font-mono">{formatRupees(item.costPaise)}</td>
                          <td className="py-3 px-4 text-right font-mono font-bold text-rose-600">
                            {formatRupees(item.tiedCapitalPaise)}
                          </td>
                          <td className="py-3 px-4 text-center">
                            <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-amber-50 text-amber-700 border border-amber-200">
                              {item.unmovedDays} days idle
                            </span>
                          </td>
                          <td className="py-3 px-4 text-center">
                            <button
                              type="button"
                              onClick={() => alert(`Applying 15% clearance discount for ${item.name}`)}
                              className="px-3 py-1 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 text-white rounded-lg font-bold text-[11px] shadow-xs cursor-pointer"
                            >
                              Bundle / 15% Clearance
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </motion.div>
            )}

            {/* Tab 4: Rush Heatmap */}
            {activeTab === "rush" && (
              <motion.div
                key="rush"
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -12 }}
                className="p-6 glass-card rounded-2xl border border-slate-200 shadow-sm space-y-6"
              >
                <div>
                  <h4 className="font-bold text-slate-900 text-base flex items-center gap-2">
                    <Flame className="w-5 h-5 text-amber-500" /> Store Counter Traffic & Billing Heatmap
                  </h4>
                  <p className="text-xs text-slate-500 mt-0.5">
                    Plan cashier shifts and restocking intervals around historical consumer rush windows
                  </p>
                </div>

                <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
                  <div className="p-4 bg-emerald-50/70 border border-emerald-200 rounded-xl">
                    <p className="text-[11px] font-bold text-emerald-800 uppercase">Primary Rush Window</p>
                    <p className="text-xl font-bold text-emerald-950 mt-1">6:00 PM – 9:00 PM</p>
                    <p className="text-xs text-emerald-700 mt-1">30 invoices (62% of revenue)</p>
                  </div>
                  <div className="p-4 bg-teal-50/70 border border-teal-200 rounded-xl">
                    <p className="text-[11px] font-bold text-teal-800 uppercase">Morning Milk & Tea Rush</p>
                    <p className="text-xl font-bold text-teal-950 mt-1">7:30 AM – 10:00 AM</p>
                    <p className="text-xs text-teal-700 mt-1">8 invoices (high velocity)</p>
                  </div>
                  <div className="p-4 bg-slate-100 border border-slate-200 rounded-xl">
                    <p className="text-[11px] font-bold text-slate-700 uppercase">Afternoon Restock Window</p>
                    <p className="text-xl font-bold text-slate-900 mt-1">1:00 PM – 3:30 PM</p>
                    <p className="text-xs text-slate-600 mt-1">Best time for supplier receiving</p>
                  </div>
                  <div className="p-4 bg-indigo-50/70 border border-indigo-200 rounded-xl">
                    <p className="text-[11px] font-bold text-indigo-800 uppercase">Average Checkout Speed</p>
                    <p className="text-xl font-bold text-indigo-950 mt-1">38 Seconds</p>
                    <p className="text-xs text-indigo-700 mt-1">Barcode & Rapid Search POS</p>
                  </div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </main>
      </div>
    </div>
  );
}
