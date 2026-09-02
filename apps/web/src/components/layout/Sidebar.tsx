"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Store,
  LayoutDashboard,
  Package,
  Users,
  TrendingUp,
  Truck,
  FileText,
  Settings,
  Sparkles,
  Wifi,
  ChevronRight,
} from "lucide-react";

export function Sidebar() {
  const pathname = usePathname();

  const navigation = [
    { name: "Dashboard", href: "/", icon: LayoutDashboard },
    { name: "Product Catalog", href: "/catalog", icon: Package },
    { name: "Udhaar (Khata)", href: "/udhaar", icon: Users },
    { name: "Executive Analytics", href: "/analytics", icon: TrendingUp },
    { name: "Purchases & Inward", href: "/purchases", icon: Truck },
    { name: "GSTR-1 Tax Center", href: "/gst", icon: FileText },
    { name: "Store Settings", href: "/settings", icon: Settings },
  ];

  return (
    <aside className="w-64 bg-slate-900 text-slate-200 min-h-screen flex flex-col justify-between border-r border-slate-800 shadow-xl shrink-0">
      <div>
        {/* Brand Header */}
        <div className="p-6 border-b border-slate-800/80">
          <Link href="/" className="flex items-center gap-3 group">
            <div className="p-2.5 bg-gradient-to-tr from-emerald-600 to-teal-500 rounded-xl shadow-lg shadow-emerald-950/50 group-hover:scale-105 transition-transform">
              <Store className="w-5 h-5 text-white" />
            </div>
            <div>
              <div className="flex items-center gap-1.5">
                <h1 className="font-bold text-white tracking-tight text-base">KiranaOS</h1>
                <span className="text-[10px] uppercase font-bold tracking-wider px-1.5 py-0.5 rounded bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                  Cloud
                </span>
              </div>
              <p className="text-xs text-slate-400 font-medium">Back-Office Suite</p>
            </div>
          </Link>
        </div>

        {/* Store Switcher Pill */}
        <div className="px-4 pt-4 pb-2">
          <div className="p-3 bg-slate-800/60 rounded-xl border border-slate-700/50 flex items-center justify-between">
            <div className="truncate">
              <p className="text-xs font-semibold text-white truncate">Sri Lakshmi Provision</p>
              <p className="text-[11px] text-slate-400">Bengaluru • GSTIN: 29AAAAA...</p>
            </div>
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse shrink-0"></span>
          </div>
        </div>

        {/* Navigation Items */}
        <nav className="p-4 space-y-1.5">
          {navigation.map((item) => {
            const isActive = pathname === item.href;
            const Icon = item.icon;
            return (
              <Link
                key={item.name}
                href={item.href}
                className={`flex items-center justify-between px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all ${
                  isActive
                    ? "bg-emerald-600 text-white shadow-md shadow-emerald-900/40 font-semibold"
                    : "text-slate-300 hover:bg-slate-800 hover:text-white"
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon className={`w-4 h-4 ${isActive ? "text-white" : "text-slate-400"}`} />
                  <span>{item.name}</span>
                </div>
                {isActive && <ChevronRight className="w-3.5 h-3.5 opacity-80" />}
              </Link>
            );
          })}
        </nav>
      </div>

      {/* Footer Info */}
      <div className="p-4 border-t border-slate-800/80">
        <div className="p-3 bg-slate-950/60 rounded-xl border border-slate-800 text-xs space-y-2">
          <div className="flex items-center justify-between text-slate-400">
            <span className="flex items-center gap-1.5">
              <Wifi className="w-3.5 h-3.5 text-emerald-400" /> POS Sync
            </span>
            <span className="text-[11px] text-emerald-400 font-semibold">Live (0 queued)</span>
          </div>
          <div className="flex items-center justify-between text-[11px] text-slate-500 pt-1 border-t border-slate-800/60">
            <span>Version 2.0.0</span>
            <span className="flex items-center gap-1 text-slate-400">
              <Sparkles className="w-3 h-3 text-amber-400" /> Pro Edition
            </span>
          </div>
        </div>
      </div>
    </aside>
  );
}
