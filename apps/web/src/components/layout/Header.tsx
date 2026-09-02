"use client";

import React, { useState, useEffect, useRef } from "react";
import Link from "next/link";
import Image from "next/image";
import { motion, AnimatePresence } from "motion/react";
import { useAuth } from "@/contexts/AuthContext";
import {
  Search,
  Bell,
  Clock,
  User,
  ShieldCheck,
  Sparkles,
  LogOut,
  Settings,
  Store,
  ChevronDown,
} from "lucide-react";

interface HeaderProps {
  title?: string;
  subtitle?: string;
}

export function Header({ title, subtitle }: HeaderProps) {
  const { user, logout } = useAuth();
  const [timeStr, setTimeStr] = useState<string>("");
  const [profileOpen, setProfileOpen] = useState(false);
  const profileRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setTimeStr(
        now.toLocaleTimeString("en-IN", {
          hour: "2-digit",
          minute: "2-digit",
          second: "2-digit",
          hour12: true,
        })
      );
    };
    updateTime();
    const interval = setInterval(updateTime, 1000);
    return () => clearInterval(interval);
  }, []);

  // Close dropdown on click outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (profileRef.current && !profileRef.current.contains(e.target as Node)) {
        setProfileOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  return (
    <header className="h-16 bg-white/85 backdrop-blur-md border-b border-slate-200/70 px-6 flex items-center justify-between sticky top-0 z-20 shadow-xs">
      {/* Title / Search */}
      <div className="flex items-center gap-4">
        {/* Mobile Logo */}
        <Link href="/" className="lg:hidden flex items-center gap-2 shrink-0">
          <div className="p-0.5 rounded-lg bg-gradient-to-tr from-emerald-600 via-teal-500 to-emerald-400 border border-emerald-400/30 shadow-xs">
            <Image
              src="/logo.png"
              alt="KiranaOS"
              width={26}
              height={26}
              className="rounded-md object-cover"
            />
          </div>
        </Link>

        <div>
          {title ? (
            <div>
              <h2 className="text-lg font-bold text-slate-900 tracking-tight leading-tight">{title}</h2>
              {subtitle && <p className="text-xs text-slate-500 font-medium">{subtitle}</p>}
            </div>
          ) : (
            <div className="relative w-80">
              <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search products, customers, bills... (⌘K)"
                className="w-full bg-slate-100/90 hover:bg-slate-100 focus:bg-white text-xs text-slate-800 pl-9 pr-8 py-2 rounded-xl border border-slate-200/60 focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/10 focus:outline-none transition-all placeholder:text-slate-400"
              />
              <span className="absolute right-2.5 top-1/2 -translate-y-1/2 text-[10px] font-mono text-slate-400 bg-slate-200/70 px-1.5 py-0.5 rounded">
                ⌘K
              </span>
            </div>
          )}
        </div>
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-3.5">
        {/* Clock IST */}
        <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-xl bg-slate-100/90 border border-slate-200/60 text-xs font-semibold text-slate-700 font-mono">
          <Clock className="w-3.5 h-3.5 text-emerald-600" />
          <span>{timeStr || "12:00:00 PM"} IST</span>
        </div>

        {/* Counter Shift Pill */}
        <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-50 border border-emerald-200 text-xs font-semibold text-emerald-800 shadow-xs">
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-600"></span>
          </span>
          <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
          <span>Register 1: Active</span>
        </div>

        {/* Notification Bell */}
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          type="button"
          className="relative p-2 rounded-xl text-slate-600 hover:bg-slate-100 border border-transparent hover:border-slate-200/60 transition-colors"
          title="Notifications"
        >
          <Bell className="w-4 h-4" />
          <span className="w-2 h-2 rounded-full bg-rose-500 absolute top-1.5 right-1.5 ring-2 ring-white"></span>
        </motion.button>

        {/* User Profile & Dropdown */}
        <div className="relative" ref={profileRef}>
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={() => setProfileOpen(!profileOpen)}
            className="flex items-center gap-2.5 pl-3 border-l border-slate-200 cursor-pointer focus:outline-none"
          >
            <div className="w-8 h-8 rounded-xl bg-gradient-to-tr from-slate-900 via-emerald-950 to-teal-800 text-emerald-300 flex items-center justify-center font-bold text-xs shadow-sm border border-emerald-500/20">
              <User className="w-4 h-4" />
            </div>
            <div className="hidden md:block text-left">
              <p className="text-xs font-bold text-slate-800 leading-tight">
                {user?.name || "Ramesh Kumar"}
              </p>
              <p className="text-[10px] text-emerald-600 font-semibold flex items-center gap-0.5">
                <span>{user?.role || "Store Owner"}</span>
                <ChevronDown className="w-3 h-3 text-slate-400" />
              </p>
            </div>
          </motion.button>

          {/* Profile Dropdown Menu */}
          <AnimatePresence>
            {profileOpen && (
              <motion.div
                initial={{ opacity: 0, y: 8, scale: 0.96 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 8, scale: 0.96 }}
                transition={{ duration: 0.18 }}
                className="absolute right-0 mt-2 w-64 bg-white/95 backdrop-blur-xl border border-slate-200 rounded-2xl shadow-xl shadow-slate-900/10 p-3 space-y-2 z-50"
              >
                <div className="p-2.5 bg-slate-50 rounded-xl border border-slate-100">
                  <p className="text-xs font-bold text-slate-900 leading-tight">{user?.name || "Ramesh Kumar"}</p>
                  <p className="text-[11px] text-slate-500 truncate">{user?.email || "srilakshmi.kirana@gmail.com"}</p>
                  <div className="flex items-center gap-1.5 mt-2 pt-2 border-t border-slate-200/60 text-[10px] text-emerald-700 font-bold">
                    <Store className="w-3 h-3" />
                    <span className="truncate">{user?.storeName || "Sri Lakshmi Provision"}</span>
                  </div>
                </div>

                <div className="space-y-1">
                  <Link
                    href="/settings"
                    onClick={() => setProfileOpen(false)}
                    className="flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-semibold text-slate-700 hover:bg-slate-100 hover:text-slate-900 transition-colors"
                  >
                    <Settings className="w-3.5 h-3.5 text-slate-500" />
                    <span>Store Settings & POS Setup</span>
                  </Link>
                </div>

                <div className="pt-1 border-t border-slate-100">
                  <button
                    type="button"
                    onClick={() => {
                      setProfileOpen(false);
                      logout();
                    }}
                    className="w-full flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-bold text-rose-600 hover:bg-rose-50 transition-colors cursor-pointer"
                  >
                    <LogOut className="w-3.5 h-3.5" />
                    <span>Sign Out</span>
                  </button>
                </div>

                <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-[10px] text-slate-400 px-1">
                  <div className="flex items-center gap-1.5 font-semibold text-slate-600">
                    <Image src="/logo.png" alt="KiranaOS" width={14} height={14} className="rounded object-cover" />
                    <span>KiranaOS Cloud</span>
                  </div>
                  <span className="font-mono text-[9px] bg-slate-100 px-1.5 py-0.5 rounded text-slate-500 font-semibold">v2.0 Pro</span>
                </div>
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>
    </header>
  );
}
