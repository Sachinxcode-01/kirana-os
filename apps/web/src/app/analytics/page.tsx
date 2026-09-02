"use client";

import React from "react";
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
} from "lucide-react";
import { DayEndZReport } from "@/types";

const SAMPLE_Z_REPORTS: DayEndZReport[] = [
  {
    shiftId: "s1",
    registerName: "Main Counter 1",
    cashierName: "Ramesh Kumar",
    openedAt: "Today, 08:30 AM",
    closedAt: "Pending (Live Shift)",
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
  { name: "Patanjali Honey 500g", currentStock: 18, costPaise: 16000, tiedCapitalPaise: 288000, unmovedDays: 72 },
  { name: "Dabur Red Toothpaste 300g", currentStock: 24, costPaise: 9500, tiedCapitalPaise: 228000, unmovedDays: 65 },
  { name: "Everest Sambhar Masala 100g", currentStock: 30, costPaise: 4200, tiedCapitalPaise: 126000, unmovedDays: 60 },
];

export default function AnalyticsPage() {
  const formatRupees = (paise: number) => `₹${(paise / 100).toFixed(2)}`;

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />

      <div className="flex-1 flex flex-col min-w-0">
        <Header
          title="Executive Analytics & Day-End Z-Reports"
          subtitle="Real-time financial performance, cash drawer reconciliation, and dead stock analysis"
        />

        <main className="p-8 space-y-6 flex-1 overflow-auto">
          {/* Top KPI Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="p-5 bg-white rounded-2xl border border-slate-200/80 shadow-xs">
              <div className="flex items-center justify-between">
                <span className="text-xs text-slate-500 font-semibold uppercase">Gross Revenue (Today)</span>
                <div className="p-2 bg-emerald-50 text-emerald-600 rounded-xl">
                  <DollarSign className="w-4 h-4" />
                </div>
              </div>
              <h3 className="text-2xl font-black font-mono mt-2 text-slate-900">₹24,500.00</h3>
              <div className="flex items-center gap-1.5 mt-2 text-xs text-emerald-600 font-bold">
                <ArrowUpRight className="w-3.5 h-3.5" /> +14.2% vs yesterday
              </div>
            </div>

            <div className="p-5 bg-white rounded-2xl border border-slate-200/80 shadow-xs">
              <div className="flex items-center justify-between">
                <span className="text-xs text-slate-500 font-semibold uppercase">Estimated Gross Profit</span>
                <div className="p-2 bg-teal-50 text-teal-600 rounded-xl">
                  <Percent className="w-4 h-4" />
                </div>
              </div>
              <h3 className="text-2xl font-black font-mono mt-2 text-slate-900">₹5,240.00</h3>
              <p className="text-xs text-teal-700 font-semibold mt-2">21.4% Gross Margin</p>
            </div>

            <div className="p-5 bg-white rounded-2xl border border-slate-200/80 shadow-xs">
              <div className="flex items-center justify-between">
                <span className="text-xs text-slate-500 font-semibold uppercase">Bills Finalized</span>
                <div className="p-2 bg-indigo-50 text-indigo-600 rounded-xl">
                  <ShoppingCart className="w-4 h-4" />
                </div>
              </div>
              <h3 className="text-2xl font-black font-mono mt-2 text-slate-900">42 Invoices</h3>
              <p className="text-xs text-slate-500 font-medium mt-2">Avg Ticket: ₹583.33</p>
            </div>

            <div className="p-5 bg-white rounded-2xl border border-slate-200/80 shadow-xs">
              <div className="flex items-center justify-between">
                <span className="text-xs text-slate-500 font-semibold uppercase">Cash Drawer Status</span>
                <div className="p-2 bg-emerald-50 text-emerald-600 rounded-xl">
                  <ShieldCheck className="w-4 h-4" />
                </div>
              </div>
              <h3 className="text-2xl font-black font-mono mt-2 text-emerald-600">100% Balanced</h3>
              <p className="text-xs text-slate-500 font-medium mt-2">0 Paise Variance</p>
            </div>
          </div>

          {/* Payment Method Split & Rush Velocity */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Payment Method Distribution */}
            <div className="p-6 bg-white rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
              <h4 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                <PieChart className="w-4 h-4 text-emerald-600" /> Payment Methods Breakdown
              </h4>

              <div className="space-y-3 text-xs">
                <div>
                  <div className="flex justify-between font-semibold text-slate-700 mb-1">
                    <span>Physical Cash</span>
                    <span className="font-mono">₹14,750.00 (60.2%)</span>
                  </div>
                  <div className="w-full bg-slate-100 h-2.5 rounded-full overflow-hidden">
                    <div className="bg-emerald-500 h-full rounded-full" style={{ width: "60.2%" }}></div>
                  </div>
                </div>

                <div>
                  <div className="flex justify-between font-semibold text-slate-700 mb-1">
                    <span>UPI / Bharat QR</span>
                    <span className="font-mono">₹8,250.00 (33.7%)</span>
                  </div>
                  <div className="w-full bg-slate-100 h-2.5 rounded-full overflow-hidden">
                    <div className="bg-teal-500 h-full rounded-full" style={{ width: "33.7%" }}></div>
                  </div>
                </div>

                <div>
                  <div className="flex justify-between font-semibold text-slate-700 mb-1">
                    <span>Udhaar (Khata Credit)</span>
                    <span className="font-mono">₹1,500.00 (6.1%)</span>
                  </div>
                  <div className="w-full bg-slate-100 h-2.5 rounded-full overflow-hidden">
                    <div className="bg-amber-500 h-full rounded-full" style={{ width: "6.1%" }}></div>
                  </div>
                </div>
              </div>
            </div>

            {/* Peak Rush Hours Heatmap */}
            <div className="lg:col-span-2 p-6 bg-white rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
              <div className="flex items-center justify-between">
                <h4 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <Clock className="w-4 h-4 text-emerald-600" /> Hourly Billing Velocity (Rush Window)
                </h4>
                <span className="text-[11px] font-bold text-emerald-700 px-2.5 py-1 bg-emerald-50 rounded-lg border border-emerald-200">
                  Peak: 6:00 PM – 8:30 PM
                </span>
              </div>

              {/* Simple Bar Chart */}
              <div className="grid grid-cols-8 gap-2 items-end h-32 pt-4">
                {[
                  { hour: "9 AM", count: 3, h: "20%" },
                  { hour: "11 AM", count: 5, h: "35%" },
                  { hour: "1 PM", count: 4, h: "28%" },
                  { hour: "3 PM", count: 2, h: "15%" },
                  { hour: "5 PM", count: 8, h: "55%" },
                  { hour: "7 PM", count: 15, h: "95%", peak: true },
                  { hour: "8 PM", count: 12, h: "80%", peak: true },
                  { hour: "9 PM", count: 6, h: "40%" },
                ].map((item) => (
                  <div key={item.hour} className="flex flex-col items-center gap-1.5 h-full justify-end">
                    <div
                      className={`w-full rounded-t-lg transition-all ${
                        item.peak ? "bg-emerald-600" : "bg-slate-200"
                      }`}
                      style={{ height: item.h }}
                      title={`${item.count} bills finalized`}
                    ></div>
                    <span className="text-[10px] font-semibold text-slate-500">{item.hour}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Dead Stock & Tied Capital Alert */}
          <div className="p-6 bg-white rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h4 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <PackageX className="w-4 h-4 text-rose-600" /> Slow-Moving & Dead Stock Liquidation
                </h4>
                <p className="text-xs text-slate-500">Unmoved inventory over 60+ days with tied-up capital</p>
              </div>
              <span className="text-xs font-bold font-mono text-rose-600 bg-rose-50 px-3 py-1.5 rounded-xl border border-rose-200">
                Total Tied Capital: ₹6,420.00
              </span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase">
                    <th className="py-2.5 px-3">Product Name</th>
                    <th className="py-2.5 px-3 text-center">Unsold Units</th>
                    <th className="py-2.5 px-3 text-right">Unit Cost</th>
                    <th className="py-2.5 px-3 text-right">Capital Tied Up</th>
                    <th className="py-2.5 px-3 text-center">Unmoved Days</th>
                    <th className="py-2.5 px-3 text-center">Recommendation</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {DEAD_STOCK_ITEMS.map((item) => (
                    <tr key={item.name} className="hover:bg-slate-50/50">
                      <td className="py-2.5 px-3 font-bold text-slate-900">{item.name}</td>
                      <td className="py-2.5 px-3 text-center">{item.currentStock} units</td>
                      <td className="py-2.5 px-3 text-right font-mono">{formatRupees(item.costPaise)}</td>
                      <td className="py-2.5 px-3 text-right font-mono font-bold text-rose-600">
                        {formatRupees(item.tiedCapitalPaise)}
                      </td>
                      <td className="py-2.5 px-3 text-center">
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-amber-50 text-amber-700 border border-amber-200">
                          {item.unmovedDays} days
                        </span>
                      </td>
                      <td className="py-2.5 px-3 text-center">
                        <button
                          type="button"
                          className="px-2.5 py-1 rounded-lg text-[10px] font-bold bg-slate-900 text-white hover:bg-slate-800"
                        >
                          Create 10% Combo Bundle
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Day-End Z-Report History Table */}
          <div className="p-6 bg-white rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h4 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <FileCheck2 className="w-4 h-4 text-emerald-600" /> Day-End Z-Report Shift Reconciliations
                </h4>
                <p className="text-xs text-slate-500">Authoritative physical cash drawer vs recorded system sales</p>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase">
                    <th className="py-2.5 px-3">Register & Shift ID</th>
                    <th className="py-2.5 px-3">Cashier</th>
                    <th className="py-2.5 px-3 text-right">Opening Cash</th>
                    <th className="py-2.5 px-3 text-right">Gross Sales</th>
                    <th className="py-2.5 px-3 text-right">Actual Drawer Cash</th>
                    <th className="py-2.5 px-3 text-center">Variance Audit</th>
                    <th className="py-2.5 px-3 text-center">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {SAMPLE_Z_REPORTS.map((r) => (
                    <tr key={r.shiftId} className="hover:bg-slate-50/50">
                      <td className="py-3 px-3">
                        <div className="font-bold text-slate-900">{r.registerName}</div>
                        <div className="text-[10px] text-slate-400">{r.openedAt}</div>
                      </td>
                      <td className="py-3 px-3 font-medium text-slate-700">{r.cashierName}</td>
                      <td className="py-3 px-3 text-right font-mono">{formatRupees(r.openingCashPaise)}</td>
                      <td className="py-3 px-3 text-right font-mono font-bold text-slate-900">
                        {formatRupees(r.grossSalesPaise)}
                      </td>
                      <td className="py-3 px-3 text-right font-mono font-bold text-emerald-700">
                        {formatRupees(r.actualCashPaise)}
                      </td>
                      <td className="py-3 px-3 text-center">
                        <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                          ✓ 0.00 Variance (Balanced)
                        </span>
                      </td>
                      <td className="py-3 px-3 text-center">
                        <span className="text-[11px] font-semibold text-slate-500">{r.closedAt}</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
