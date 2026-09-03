"use client";

import React from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { motion } from "motion/react";
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
import { useLanguage } from "@/contexts/LanguageContext";

export function Sidebar() {
  const pathname = usePathname();
  const { t } = useLanguage();

  const navigation = [
    { name: t("nav.dashboard"), href: "/", icon: LayoutDashboard },
    { name: t("nav.catalog"), href: "/catalog", icon: Package, hotkey: "F1" },
    { name: t("nav.udhaar"), href: "/udhaar", icon: Users },
    { name: t("nav.analytics"), href: "/analytics", icon: TrendingUp },
    { name: t("nav.purchases"), href: "/purchases", icon: Truck },
    { name: t("nav.gst"), href: "/gst", icon: FileText },
    { name: t("nav.settings"), href: "/settings", icon: Settings },
  ];

  return (
    <aside className="w-64 bg-slate-900 text-slate-200 min-h-screen flex flex-col justify-between border-r border-slate-800/80 shadow-2xl shrink-0 z-30 relative select-none">
      <div>
        {/* Brand Header */}
        <div className="p-6 border-b border-slate-800/80">
          <Link href="/" className="flex items-center gap-3 group">
            <motion.div
              whileHover={{ scale: 1.08, rotate: 2 }}
              whileTap={{ scale: 0.95 }}
              className="relative p-1 bg-gradient-to-tr from-emerald-600 via-teal-500 to-emerald-400 rounded-xl shadow-lg shadow-emerald-950/60 border border-emerald-400/20 shrink-0 overflow-hidden flex items-center justify-center"
            >
              <Image
                src="/logo.png"
                alt="KiranaOS Logo"
                width={36}
                height={36}
                className="rounded-lg object-cover"
                priority
              />
            </motion.div>
            <div>
              <div className="flex items-center gap-1.5">
                <h1 className="font-bold text-white tracking-tight text-base group-hover:text-emerald-300 transition-colors">
                  KiranaOS
                </h1>
                <span className="text-[9px] uppercase font-extrabold tracking-wider px-1.5 py-0.5 rounded-full bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 shadow-xs shadow-emerald-500/20">
                  Cloud
                </span>
              </div>
              <p className="text-xs text-slate-400 font-medium">Back-Office Suite</p>
            </div>
          </Link>
        </div>

        {/* Store Switcher Pill */}
        <div className="px-4 pt-4 pb-2">
          <motion.div
            whileHover={{ scale: 1.01 }}
            className="p-3 bg-gradient-to-b from-slate-800/80 to-slate-800/40 rounded-xl border border-slate-700/60 flex items-center justify-between shadow-inner"
          >
            <div className="truncate">
              <p className="text-xs font-semibold text-white truncate">Sri Lakshmi Provision</p>
              <p className="text-[11px] text-slate-400">Bengaluru • GSTIN: 29AAAAA...</p>
            </div>
            <div className="relative flex items-center justify-center shrink-0">
              <span className="absolute inline-flex h-3 w-3 animate-ping rounded-full bg-emerald-400 opacity-60"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-400"></span>
            </div>
          </motion.div>
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
                className="relative block"
              >
                <motion.div
                  whileHover={{ x: 3 }}
                  whileTap={{ scale: 0.98 }}
                  className={`flex items-center justify-between px-3.5 py-2.5 rounded-xl text-sm font-medium transition-colors relative z-10 ${
                    isActive
                      ? "text-white font-semibold"
                      : "text-slate-300 hover:text-white"
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <Icon
                      className={`w-4 h-4 transition-colors ${
                        isActive ? "text-emerald-300" : "text-slate-400 group-hover:text-slate-200"
                      }`}
                    />
                    <span>{item.name}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    {item.hotkey && (
                      <kbd className={`px-1.5 py-0.2 text-[10px] font-mono font-bold rounded ${
                        isActive ? "bg-emerald-700/60 text-white" : "bg-slate-800 text-slate-400 border border-slate-700"
                      }`}>
                        {item.hotkey}
                      </kbd>
                    )}
                    {isActive && (
                      <motion.div
                        initial={{ opacity: 0, x: -4 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ duration: 0.2 }}
                      >
                        <ChevronRight className="w-3.5 h-3.5 text-emerald-300" />
                      </motion.div>
                    )}
                  </div>
                </motion.div>

                {/* Animated Active Pill Indicator */}
                {isActive && (
                  <motion.div
                    layoutId="activeNavBackground"
                    transition={{ type: "spring", stiffness: 350, damping: 30 }}
                    className="absolute inset-0 bg-gradient-to-r from-emerald-600 to-teal-600 rounded-xl shadow-md shadow-emerald-950/60 border border-emerald-400/30"
                  />
                )}
              </Link>
            );
          })}
        </nav>
      </div>

      {/* Footer Info */}
      <div className="p-4 border-t border-slate-800/80">
        <div className="p-3 bg-slate-950/70 rounded-xl border border-slate-800/90 text-xs space-y-2 backdrop-blur-xs">
          <div className="flex items-center justify-between text-slate-400">
            <span className="flex items-center gap-1.5">
              <Wifi className="w-3.5 h-3.5 text-emerald-400" /> POS Sync
            </span>
            <span className="text-[11px] text-emerald-400 font-bold tracking-tight">Live Telemetry</span>
          </div>
          <div className="flex items-center justify-between text-[11px] text-slate-400 pt-1.5 border-t border-slate-800/60">
            <span className="text-slate-500">v2.0.0</span>
            <span className="flex items-center gap-1 text-amber-300 font-semibold">
              <Sparkles className="w-3 h-3 text-amber-400" /> Pro Edition
            </span>
          </div>
        </div>
      </div>
    </aside>
  );
}
