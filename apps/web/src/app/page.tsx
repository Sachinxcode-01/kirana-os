"use client";

import React from "react";
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
} from "lucide-react";

export default function BackOfficeDashboard() {
  const kpis = [
    {
      title: "Today's Revenue",
      value: "₹24,500.00",
      change: "+14.2% vs yesterday",
      icon: ShoppingCart,
      color: "emerald",
      bgGradient: "from-emerald-500/10 to-teal-500/5",
      borderColor: "border-emerald-200/80",
    },
    {
      title: "Bills Finalized",
      value: "42 Invoices",
      change: "Avg: ₹583.33 / bill",
      icon: ShoppingCart,
      color: "teal",
      bgGradient: "from-teal-500/10 to-cyan-500/5",
      borderColor: "border-teal-200/80",
    },
    {
      title: "Pending Udhaar (Khata)",
      value: "₹18,500.00",
      change: "4 accounts due today",
      icon: Users,
      color: "amber",
      bgGradient: "from-amber-500/10 to-orange-500/5",
      borderColor: "border-amber-200/80",
    },
    {
      title: "Active Catalog SKUs",
      value: "248 Products",
      change: "8 Low Stock alerts",
      icon: Package,
      color: "indigo",
      bgGradient: "from-indigo-500/10 to-purple-500/5",
      borderColor: "border-indigo-200/80",
    },
  ];

  const recentBills = [
    { id: "INV-2026-0042", time: "04:32 PM", customer: "Anil Sharma", amount: "₹1,850.00", mode: "Udhaar", status: "completed" },
    { id: "INV-2026-0041", time: "04:15 PM", customer: "Walk-in Retail", amount: "₹340.00", mode: "UPI QR", status: "completed" },
    { id: "INV-2026-0040", time: "03:50 PM", customer: "Sunita Patel", amount: "₹820.00", mode: "Cash", status: "completed" },
    { id: "INV-2026-0039", time: "03:20 PM", customer: "Walk-in Retail", amount: "₹120.00", mode: "Cash", status: "completed" },
  ];

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

      <Sidebar />

      <div className="flex-1 flex flex-col min-w-0 z-10">
        <Header
          title="Executive Store Dashboard"
          subtitle="Real-time live telemetry from POS counters & cloud database"
        />

        <main className="p-8 space-y-6 flex-1 overflow-auto">
          {/* Quick Action Bar */}
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex flex-wrap items-center gap-3 p-3.5 glass-card rounded-2xl shadow-xs"
          >
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider pl-2 pr-1 flex items-center gap-1.5">
              <Sparkles className="w-3.5 h-3.5 text-amber-500" /> Quick Actions:
            </span>
            <Link
              href="/catalog"
              className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-white bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 shadow-sm shadow-emerald-950/20 transition-all hover:scale-102"
            >
              <Plus className="w-3.5 h-3.5" /> Add New SKU
            </Link>
            <Link
              href="/udhaar"
              className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-slate-700 bg-white hover:bg-slate-50 border border-slate-200/80 shadow-xs transition-all hover:scale-102"
            >
              <Send className="w-3.5 h-3.5 text-emerald-600" /> Send Khata Reminder
            </Link>
            <Link
              href="/purchases"
              className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-slate-700 bg-white hover:bg-slate-50 border border-slate-200/80 shadow-xs transition-all hover:scale-102"
            >
              <Truck className="w-3.5 h-3.5 text-teal-600" /> Auto-Replenish PO
            </Link>
            <Link
              href="/gst"
              className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-slate-700 bg-white hover:bg-slate-50 border border-slate-200/80 shadow-xs transition-all hover:scale-102"
            >
              <Download className="w-3.5 h-3.5 text-slate-500" /> Export GSTR-1
            </Link>
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
                  className={`p-5 glass-card rounded-2xl relative overflow-hidden shadow-xs hover:shadow-md transition-shadow group border ${kpi.borderColor}`}
                >
                  <div className={`absolute top-0 right-0 w-24 h-24 bg-gradient-to-br ${kpi.bgGradient} rounded-full blur-xl -mr-6 -mt-6`}></div>
                  <div className="flex items-center justify-between">
                    <span className="text-xs text-slate-500 font-bold uppercase tracking-wider">{kpi.title}</span>
                    <div className="p-2.5 bg-slate-100 rounded-xl text-slate-700 group-hover:bg-emerald-50 group-hover:text-emerald-700 transition-colors">
                      <Icon className="w-4 h-4" />
                    </div>
                  </div>
                  <h3 className="text-3xl font-black font-mono mt-3 text-slate-900 tracking-tight">{kpi.value}</h3>
                  <div className="flex items-center gap-1.5 mt-2.5 text-xs text-emerald-700 font-bold">
                    <ArrowUpRight className="w-3.5 h-3.5" /> {kpi.change}
                  </div>
                </motion.div>
              );
            })}
          </motion.div>

          {/* Activity Feeds & Low Stock */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Live POS Sales Stream */}
            <motion.div
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.2 }}
              className="lg:col-span-2 p-6 glass-card rounded-2xl shadow-xs space-y-5"
            >
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                    <ShoppingCart className="w-4 h-4 text-emerald-600" /> Live Invoices Stream (Counter 1)
                  </h4>
                  <p className="text-xs text-slate-500 mt-0.5">Real-time synchronized transactions</p>
                </div>
                <Link
                  href="/analytics"
                  className="flex items-center gap-1 text-xs font-bold text-emerald-700 hover:text-emerald-800 transition-colors"
                >
                  <span>Analytics Suite</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </div>

              <div className="overflow-x-auto rounded-xl border border-slate-200/80">
                <table className="w-full text-left text-xs border-collapse">
                  <thead>
                    <tr className="bg-slate-100/80 border-b border-slate-200 text-[11px] font-bold text-slate-600 uppercase">
                      <th className="py-3 px-3.5">Bill Number</th>
                      <th className="py-3 px-3.5">Time</th>
                      <th className="py-3 px-3.5">Customer</th>
                      <th className="py-3 px-3.5 text-right">Amount</th>
                      <th className="py-3 px-3.5 text-center">Payment Mode</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 font-medium">
                    {recentBills.map((b) => (
                      <tr key={b.id} className="hover:bg-slate-50/70 transition-colors">
                        <td className="py-3 px-3.5 font-mono font-bold text-slate-900">{b.id}</td>
                        <td className="py-3 px-3.5 text-slate-400 font-mono text-[11px]">{b.time}</td>
                        <td className="py-3 px-3.5 text-slate-700 font-semibold">{b.customer}</td>
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
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </motion.div>

            {/* Critical Low Stock Column */}
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
                {lowStockAlerts.map((item) => (
                  <motion.div
                    whileHover={{ scale: 1.01 }}
                    key={item.name}
                    className="p-3 bg-amber-50/70 rounded-xl border border-amber-200/80 space-y-1 shadow-xs"
                  >
                    <p className="font-bold text-slate-900 leading-tight">{item.name}</p>
                    <div className="flex justify-between items-center text-[11px] text-amber-900 font-semibold pt-1">
                      <span>In Stock: <strong className="font-mono">{item.current}</strong> {item.unit}</span>
                      <span className="text-rose-600 font-bold bg-rose-50 px-2 py-0.5 rounded border border-rose-200">
                        Min: {item.min} {item.unit}
                      </span>
                    </div>
                  </motion.div>
                ))}

                <Link
                  href="/purchases"
                  className="w-full flex items-center justify-center gap-1.5 py-2.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold shadow-md shadow-slate-950/20 transition-all mt-2"
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
