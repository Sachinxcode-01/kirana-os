"use client";

import React, { useState, useEffect } from "react";
import { Search, Bell, Clock, User, ShieldCheck } from "lucide-react";

interface HeaderProps {
  title?: string;
  subtitle?: string;
}

export function Header({ title, subtitle }: HeaderProps) {
  const [timeStr, setTimeStr] = useState<string>("");

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

  return (
    <header className="h-16 bg-white border-b border-slate-200/80 px-6 flex items-center justify-between sticky top-0 z-20 shadow-xs">
      {/* Title / Search */}
      <div className="flex items-center gap-6">
        <div>
          {title ? (
            <div>
              <h2 className="text-lg font-bold text-slate-900 leading-tight">{title}</h2>
              {subtitle && <p className="text-xs text-slate-500 font-medium">{subtitle}</p>}
            </div>
          ) : (
            <div className="relative w-72">
              <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search products, customers, bills..."
                className="w-full bg-slate-100/80 hover:bg-slate-100 focus:bg-white text-xs text-slate-800 pl-9 pr-4 py-2 rounded-xl border border-transparent focus:border-emerald-500 focus:outline-none transition-all placeholder:text-slate-400"
              />
            </div>
          )}
        </div>
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-4">
        {/* Clock IST */}
        <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-lg bg-slate-100 text-xs font-semibold text-slate-700">
          <Clock className="w-3.5 h-3.5 text-slate-500" />
          <span>{timeStr || "12:00:00 PM"} IST</span>
        </div>

        {/* Counter Shift Pill */}
        <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-emerald-50 border border-emerald-200 text-xs font-semibold text-emerald-800">
          <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
          <span>Register 1: Open</span>
        </div>

        {/* Notification Bell */}
        <button
          type="button"
          className="relative p-2 rounded-xl text-slate-600 hover:bg-slate-100 transition-colors"
          title="Notifications"
        >
          <Bell className="w-4 h-4" />
          <span className="w-2 h-2 rounded-full bg-rose-500 absolute top-1.5 right-1.5"></span>
        </button>

        {/* User Profile */}
        <div className="flex items-center gap-2.5 pl-3 border-l border-slate-200">
          <div className="w-8 h-8 rounded-xl bg-gradient-to-tr from-slate-800 to-slate-700 text-white flex items-center justify-center font-bold text-xs shadow-xs">
            <User className="w-4 h-4" />
          </div>
          <div className="hidden md:block text-left">
            <p className="text-xs font-bold text-slate-800 leading-tight">Ramesh Kumar</p>
            <p className="text-[10px] text-slate-500 font-medium">Store Owner</p>
          </div>
        </div>
      </div>
    </header>
  );
}
