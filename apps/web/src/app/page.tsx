import React from "react";
import Link from "next/link";
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
} from "lucide-react";

export default function BackOfficeDashboard() {
  const kpis = [
    {
      title: "Today's Revenue",
      value: "₹24,500.00",
      change: "+14.2% vs yesterday",
      icon: ShoppingCart,
      color: "emerald",
    },
    {
      title: "Bills Finalized",
      value: "42 Invoices",
      change: "Avg: ₹583.33 / bill",
      icon: ShoppingCart,
      color: "teal",
    },
    {
      title: "Pending Udhaar (Khata)",
      value: "₹18,500.00",
      change: "4 accounts due",
      icon: Users,
      color: "amber",
    },
    {
      title: "Active Catalog SKUs",
      value: "248 Products",
      change: "8 Low Stock alerts",
      icon: Package,
      color: "indigo",
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

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />

      <div className="flex-1 flex flex-col min-w-0">
        <Header
          title="Executive Store Dashboard"
          subtitle="Real-time live telemetry from POS counters & cloud database"
        />

        <main className="p-8 space-y-6 flex-1 overflow-auto">
          {/* Quick Action Bar */}
          <div className="flex flex-wrap items-center gap-3 p-4 bg-white rounded-2xl border border-slate-200/80 shadow-xs">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider pr-2">Quick Actions:</span>
            <Link
              href="/catalog"
              className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 shadow-xs transition-all"
            >
              <Plus className="w-3.5 h-3.5" /> Add New SKU
            </Link>
            <Link
              href="/udhaar"
              className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-slate-700 bg-slate-100 hover:bg-slate-200 transition-all"
            >
              <Send className="w-3.5 h-3.5 text-emerald-600" /> Send Khata Reminder
            </Link>
            <Link
              href="/purchases"
              className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-slate-700 bg-slate-100 hover:bg-slate-200 transition-all"
            >
              <Sparkles className="w-3.5 h-3.5 text-amber-500" /> Auto-Replenish PO
            </Link>
            <Link
              href="/gst"
              className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold text-slate-700 bg-slate-100 hover:bg-slate-200 transition-all"
            >
              <Download className="w-3.5 h-3.5 text-slate-500" /> Export GSTR-1
            </Link>
          </div>

          {/* Top KPI Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {kpis.map((kpi) => {
              const Icon = kpi.icon;
              return (
                <div key={kpi.title} className="p-5 bg-white rounded-2xl border border-slate-200/80 shadow-xs">
                  <div className="flex items-center justify-between">
                    <span className="text-xs text-slate-500 font-semibold uppercase">{kpi.title}</span>
                    <div className="p-2 bg-slate-100 rounded-xl text-slate-700">
                      <Icon className="w-4 h-4" />
                    </div>
                  </div>
                  <h3 className="text-2xl font-black font-mono mt-2 text-slate-900">{kpi.value}</h3>
                  <div className="flex items-center gap-1.5 mt-2 text-xs text-emerald-600 font-bold">
                    <ArrowUpRight className="w-3.5 h-3.5" /> {kpi.change}
                  </div>
                </div>
              );
            })}
          </div>

          {/* Activity Feeds & Low Stock */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Live POS Sales Stream */}
            <div className="lg:col-span-2 p-6 bg-white rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                    <ShoppingCart className="w-4 h-4 text-emerald-600" /> Live Invoices Stream (Counter 1)
                  </h4>
                  <p className="text-xs text-slate-500">Real-time synchronized transactions</p>
                </div>
                <Link
                  href="/analytics"
                  className="text-xs font-bold text-emerald-700 hover:underline"
                >
                  View All Bills &rarr;
                </Link>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs border-collapse">
                  <thead>
                    <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase">
                      <th className="py-2.5 px-3">Bill Number</th>
                      <th className="py-2.5 px-3">Time</th>
                      <th className="py-2.5 px-3">Customer</th>
                      <th className="py-2.5 px-3 text-right">Amount</th>
                      <th className="py-2.5 px-3 text-center">Payment Mode</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 font-medium">
                    {recentBills.map((b) => (
                      <tr key={b.id} className="hover:bg-slate-50/50">
                        <td className="py-3 px-3 font-mono font-bold text-slate-900">{b.id}</td>
                        <td className="py-3 px-3 text-slate-400 font-mono text-[11px]">{b.time}</td>
                        <td className="py-3 px-3 text-slate-700">{b.customer}</td>
                        <td className="py-3 px-3 text-right font-mono font-bold text-slate-900">{b.amount}</td>
                        <td className="py-3 px-3 text-center">
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 text-slate-700 border border-slate-200">
                            {b.mode}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Critical Low Stock Column */}
            <div className="p-6 bg-white rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
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
                  <div key={item.name} className="p-3 bg-amber-50/60 rounded-xl border border-amber-200/70 space-y-1">
                    <p className="font-bold text-slate-900 leading-tight">{item.name}</p>
                    <div className="flex justify-between items-center text-[11px] text-amber-900 font-semibold pt-1">
                      <span>Stock: {item.current} {item.unit}</span>
                      <span className="text-rose-600 font-bold">Min: {item.min} {item.unit}</span>
                    </div>
                  </div>
                ))}

                <Link
                  href="/purchases"
                  className="w-full flex items-center justify-center gap-1.5 py-2.5 rounded-xl bg-slate-900 text-white text-xs font-bold hover:bg-slate-800 transition-all mt-2"
                >
                  <Truck className="w-3.5 h-3.5" /> Order Replenishment
                </Link>
              </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
