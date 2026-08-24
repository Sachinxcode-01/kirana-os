import React from "react";
import { Store, ShoppingCart, Users, Package, AlertTriangle, ArrowUpRight } from "lucide-react";

export default function BackOfficeDashboard() {
  const kpis = [
    { title: "Today's Revenue", value: "₹18,450.00", icon: ShoppingCart, change: "+12.4%" },
    { title: "Bills Generated", value: "42", icon: Store, change: "+5 bills" },
    { title: "Active Udhaar Debt", value: "₹38,500.00", icon: Users, alert: true },
    { title: "Low Stock Items", value: "4 Products", icon: AlertTriangle, alert: true },
  ];

  return (
    <div className="min-h-screen flex flex-col md:flex-row">
      {/* Sidebar Navigation */}
      <aside className="w-full md:w-64 bg-slate-900 text-white p-6 flex flex-col">
        <div className="flex items-center gap-3 mb-8">
          <div className="p-2 bg-emerald-600 rounded-lg">
            <Store className="w-6 h-6 text-white" />
          </div>
          <div>
            <h1 className="font-bold text-lg leading-tight">KiranaOS</h1>
            <p className="text-xs text-slate-400">Back-Office Portal</p>
          </div>
        </div>

        <nav className="space-y-1 text-sm font-medium flex-1">
          <a href="#" className="flex items-center gap-3 px-3 py-2.5 rounded-lg bg-emerald-700/40 text-emerald-400">
            <Store className="w-4 h-4" /> Dashboard
          </a>
          <a href="#" className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-slate-300 hover:bg-slate-800">
            <Package className="w-4 h-4" /> Products Catalog
          </a>
          <a href="#" className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-slate-300 hover:bg-slate-800">
            <Users className="w-4 h-4" /> Udhaar Ledger
          </a>
          <a href="#" className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-slate-300 hover:bg-slate-800">
            <ShoppingCart className="w-4 h-4" /> Invoices & Sales
          </a>
        </nav>

        <div className="pt-6 border-t border-slate-800 text-xs text-slate-400">
          <p className="font-semibold text-slate-200">Gupta General Store</p>
          <p>GSTIN: 29AAAAA0000A1Z5</p>
        </div>
      </aside>

      {/* Main Content View */}
      <main className="flex-1 p-6 md:p-8 overflow-y-auto">
        <header className="flex justify-between items-center mb-8">
          <div>
            <h2 className="text-2xl font-bold text-slate-900">Store Analytics & Management</h2>
            <p className="text-sm text-slate-500">Live cloud sync connected with Mobile POS</p>
          </div>
          <div className="flex items-center gap-2 px-3 py-1.5 bg-emerald-50 text-emerald-700 border border-emerald-200 rounded-full text-xs font-semibold">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
            Cloud Synced
          </div>
        </header>

        {/* Metric Cards Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          {kpis.map((kpi, idx) => (
            <div key={idx} className="p-5 bg-white rounded-xl border border-slate-200 shadow-sm">
              <div className="flex justify-between items-start mb-3">
                <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">{kpi.title}</span>
                <kpi.icon className={`w-5 h-5 ${kpi.alert ? 'text-amber-500' : 'text-emerald-600'}`} />
              </div>
              <p className="text-2xl font-bold text-slate-900">{kpi.value}</p>
              {kpi.change && (
                <div className="flex items-center gap-1 mt-2 text-xs font-medium text-emerald-600">
                  <ArrowUpRight className="w-3.5 h-3.5" />
                  <span>{kpi.change} vs yesterday</span>
                </div>
              )}
            </div>
          ))}
        </div>
      </main>
    </div>
  );
}
