"use client";

import React, { useState, useEffect, useRef } from "react";
import Link from "next/link";
import Image from "next/image";
import { motion, AnimatePresence } from "motion/react";
import { useAuth } from "@/contexts/AuthContext";
import { CommandPalette } from "@/components/layout/CommandPalette";
import { KeyboardShortcutsModal } from "@/components/pos/KeyboardShortcutsModal";
import { QuickTenderModal } from "@/components/pos/QuickTenderModal";
import { ThermalReceiptModal } from "@/components/pos/ThermalReceiptModal";
import { DayEndZReportModal } from "@/components/pos/DayEndZReportModal";
import { SyncStatusPill } from "@/components/layout/SyncStatusPill";
import { LanguageSelector } from "@/components/layout/LanguageSelector";
import { VoiceSearchButton } from "@/components/pos/VoiceSearchButton";
import { usePosHotkeys } from "@/hooks/usePosHotkeys";
import { useLanguage } from "@/contexts/LanguageContext";
import { posAudio } from "@/utils/audioFeedback";
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
  AlertTriangle,
  CreditCard,
  Receipt,
  Check,
  X,
  Keyboard,
  Banknote,
  Printer,
  FileSpreadsheet,
  Volume2,
  VolumeX,
  Sun,
  Moon,
  Menu,
} from "lucide-react";

interface HeaderProps {
  title?: string;
  subtitle?: string;
  onMenuClick?: () => void;
}

export function Header({ title, subtitle, onMenuClick }: HeaderProps) {
  const { user, logout } = useAuth();
  const { t } = useLanguage();
  const [timeStr, setTimeStr] = useState<string>("");
  const [profileOpen, setProfileOpen] = useState(false);
  const [notifOpen, setNotifOpen] = useState(false);
  const [paletteOpen, setPaletteOpen] = useState(false);
  const [shortcutsOpen, setShortcutsOpen] = useState(false);
  const [tenderOpen, setTenderOpen] = useState(false);
  const [receiptOpen, setReceiptOpen] = useState(false);
  const [zReportOpen, setZReportOpen] = useState(false);
  const [isMuted, setIsMuted] = useState(false);
  const [isDarkMode, setIsDarkMode] = useState(false);
  const profileRef = useRef<HTMLDivElement>(null);
  const notifRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setIsMuted(posAudio.isAudioMuted());
    if (typeof window !== "undefined") {
      const saved = localStorage.getItem("kirana_theme") === "dark";
      setIsDarkMode(saved);
      if (saved) {
        document.documentElement.classList.add("dark");
      }
    }
  }, []);

  const toggleTheme = () => {
    const next = !isDarkMode;
    setIsDarkMode(next);
    posAudio.playBarcodeBeep();
    if (typeof window !== "undefined") {
      localStorage.setItem("kirana_theme", next ? "dark" : "light");
      if (next) {
        document.documentElement.classList.add("dark");
      } else {
        document.documentElement.classList.remove("dark");
      }
    }
  };

  const toggleMute = () => {
    const next = posAudio.toggleMute();
    setIsMuted(next);
    if (!next) {
      posAudio.playBarcodeBeep();
    }
  };

  // Global POS Hotkeys (F1, F4, F8, ?, Esc)
  usePosHotkeys({
    onF1: () => setPaletteOpen(true),
    onF4: () => setTenderOpen(true),
    onF8: () => setReceiptOpen(true),
    onHelp: () => setShortcutsOpen((prev) => !prev),
    onEscape: () => {
      setPaletteOpen(false);
      setShortcutsOpen(false);
      setTenderOpen(false);
      setReceiptOpen(false);
      setNotifOpen(false);
      setProfileOpen(false);
    },
  });

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

  // Global Ctrl+K / Cmd+K listener
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        setPaletteOpen((prev) => !prev);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  // Close dropdown on click outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (profileRef.current && !profileRef.current.contains(e.target as Node)) {
        setProfileOpen(false);
      }
      if (notifRef.current && !notifRef.current.contains(e.target as Node)) {
        setNotifOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const notifications = [
    {
      id: "notif-1",
      title: "Low Stock Alert: Amul Salted Butter 500g",
      desc: "Only 7 units remain on Shelf A3. Reorder advised.",
      type: "warning",
      icon: AlertTriangle,
      color: "text-amber-500",
      bg: "bg-amber-500/10",
      time: "10m ago",
    },
    {
      id: "notif-2",
      title: "Khata Payment Due: Suresh Raina",
      desc: "Outstanding credit ₹2,450.00 is overdue by 14 days.",
      type: "credit",
      icon: CreditCard,
      color: "text-rose-500",
      bg: "bg-rose-500/10",
      time: "1h ago",
    },
    {
      id: "notif-3",
      title: "GSTR-1 Monthly Filing Window Open",
      desc: "August 2026 return ready for verification and CA export.",
      type: "gst",
      icon: Receipt,
      color: "text-emerald-500",
      bg: "bg-emerald-500/10",
      time: "3h ago",
    },
  ];

  return (
    <>
      <CommandPalette isOpen={paletteOpen} onClose={() => setPaletteOpen(false)} />
      <KeyboardShortcutsModal isOpen={shortcutsOpen} onClose={() => setShortcutsOpen(false)} />
      <QuickTenderModal isOpen={tenderOpen} onClose={() => setTenderOpen(false)} />
      <ThermalReceiptModal isOpen={receiptOpen} onClose={() => setReceiptOpen(false)} />
      <DayEndZReportModal isOpen={zReportOpen} onClose={() => setZReportOpen(false)} />

      <header className="h-16 bg-white/85 backdrop-blur-md border-b border-slate-200/70 px-3 sm:px-6 flex items-center justify-between sticky top-0 z-20 shadow-xs">
        {/* Title / Search */}
        <div className="flex items-center gap-2 sm:gap-4">
          {/* Hamburger Menu on Mobile */}
          <button
            type="button"
            onClick={onMenuClick}
            className="lg:hidden p-2 -ml-1 text-slate-600 hover:text-slate-900 rounded-xl hover:bg-slate-100 transition-colors cursor-pointer"
            title="Open Menu"
          >
            <Menu className="w-5 h-5" />
          </button>

          {/* Mobile Logo */}
          <Link href="/" className="lg:hidden flex items-center gap-1.5 shrink-0">
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
                <h2 className="text-base sm:text-lg font-bold text-slate-900 tracking-tight leading-tight">{title}</h2>
                {subtitle && <p className="text-[11px] sm:text-xs text-slate-500 font-medium hidden sm:block">{subtitle}</p>}
              </div>
            ) : (
              <div className="relative w-full max-w-[160px] sm:max-w-xs md:max-w-sm group flex items-center">
                <Search className="w-4 h-4 text-slate-400 group-hover:text-emerald-500 transition-colors absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
                <div
                  onClick={() => setPaletteOpen(true)}
                  className="w-full bg-slate-100/90 group-hover:bg-slate-100/100 text-xs text-slate-500 pl-8 sm:pl-9 pr-14 sm:pr-20 py-2 rounded-xl border border-slate-200/60 group-hover:border-emerald-500/50 transition-all font-medium flex items-center justify-between cursor-pointer"
                >
                  <span className="truncate">{t("header.search")}</span>
                </div>
                <div className="absolute right-1.5 sm:right-2 top-1/2 -translate-y-1/2 flex items-center gap-0.5 sm:gap-1">
                  <VoiceSearchButton
                    onResult={(_text) => {
                      setPaletteOpen(true);
                    }}
                  />
                  <span className="hidden sm:inline text-[10px] font-mono text-slate-400 bg-slate-200/80 px-1.5 py-0.5 rounded pointer-events-none">
                    ⌘K
                  </span>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Right Controls */}
        <div className="flex items-center gap-2">
          {/* Quick Cash Tender F4 Trigger */}
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            type="button"
            onClick={() => setTenderOpen(true)}
            className="hidden md:flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white text-xs font-bold shadow-xs transition-all cursor-pointer"
            title={t("header.quickTender")}
          >
            <Banknote className="w-3.5 h-3.5" />
            <span>{t("header.quickTender")}</span>
            <kbd className="px-1.5 py-0.5 rounded text-[10px] font-mono font-bold bg-white/20 text-white">
              F4
            </kbd>
          </motion.button>

          {/* Thermal Receipt F8 Trigger */}
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            type="button"
            onClick={() => setReceiptOpen(true)}
            className="hidden sm:flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl bg-slate-100 hover:bg-slate-200/80 border border-slate-200/70 text-xs font-bold text-slate-700 transition-colors cursor-pointer"
            title={t("header.receipt")}
          >
            <Printer className="w-3.5 h-3.5 text-slate-600" />
            <span>{t("header.receipt")}</span>
            <kbd className="px-1 py-0.2 rounded text-[10px] font-mono font-bold bg-slate-200/80 text-slate-600">
              F8
            </kbd>
          </motion.button>

          {/* Day-End Z-Report Trigger */}
          <motion.button
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            type="button"
            onClick={() => setZReportOpen(true)}
            className="hidden lg:flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl bg-slate-100 hover:bg-slate-200/80 border border-slate-200/70 text-xs font-bold text-slate-700 transition-colors cursor-pointer"
            title="Day-End Cash Drawer & Z-Report Audit"
          >
            <FileSpreadsheet className="w-3.5 h-3.5 text-emerald-600" />
            <span>Z-Report</span>
          </motion.button>

          {/* Shortcuts Guide ? Trigger */}
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            type="button"
            onClick={() => setShortcutsOpen(true)}
            className="hidden sm:flex items-center gap-1 px-2 py-1.5 rounded-xl bg-slate-100 hover:bg-slate-200/80 border border-slate-200/70 text-xs font-bold text-slate-700 transition-colors cursor-pointer"
            title={t("header.shortcuts")}
          >
            <Keyboard className="w-3.5 h-3.5 text-slate-500" />
            <span className="font-mono text-[10px] bg-slate-200/80 px-1 py-0.5 rounded text-slate-600 font-bold">
              ?
            </span>
          </motion.button>

          {/* Regional Language Selector */}
          <LanguageSelector />

          {/* Audio Feedback Mute Toggle */}
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            type="button"
            onClick={toggleMute}
            className={`p-2 rounded-xl border transition-colors cursor-pointer ${
              isMuted
                ? "bg-rose-50 border-rose-200 text-rose-600 hover:bg-rose-100"
                : "bg-slate-100 hover:bg-slate-200/80 border-slate-200/70 text-slate-600 hover:text-slate-900"
            }`}
            title={isMuted ? "Unmute POS Audio Feedback" : "Mute POS Audio Feedback"}
          >
            {isMuted ? <VolumeX className="w-4 h-4" /> : <Volume2 className="w-4 h-4" />}
          </motion.button>

          {/* Glare-Free High-Contrast / Dark Counter Mode Toggle */}
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            type="button"
            onClick={toggleTheme}
            className={`p-2 rounded-xl border transition-colors cursor-pointer ${
              isDarkMode
                ? "bg-amber-500/10 border-amber-500/30 text-amber-400 hover:bg-amber-500/20"
                : "bg-slate-100 hover:bg-slate-200/80 border-slate-200/70 text-slate-600 hover:text-slate-900"
            }`}
            title={isDarkMode ? "Switch to Standard Light Mode" : "Switch to Glare-Free High-Contrast Mode"}
          >
            {isDarkMode ? <Sun className="w-4 h-4 text-amber-500" /> : <Moon className="w-4 h-4 text-slate-600" />}
          </motion.button>

          {/* Clock IST */}
          <div className="hidden xl:flex items-center gap-2 px-3 py-1.5 rounded-xl bg-slate-100/90 border border-slate-200/60 text-xs font-semibold text-slate-700 font-mono">
            <Clock className="w-3.5 h-3.5 text-emerald-600" />
            <span>{timeStr || "12:00:00 PM"} IST</span>
          </div>

          {/* Live Cloud & Sync Heartbeat Pill */}
          <SyncStatusPill />

          {/* Notification Bell */}
          <div className="relative" ref={notifRef}>
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              type="button"
              onClick={() => setNotifOpen(!notifOpen)}
              className="relative p-2 rounded-xl text-slate-600 hover:bg-slate-100 border border-transparent hover:border-slate-200/60 transition-colors cursor-pointer"
              title="Notifications"
            >
              <Bell className="w-4 h-4" />
              <span className="w-2 h-2 rounded-full bg-rose-500 absolute top-1.5 right-1.5 ring-2 ring-white"></span>
            </motion.button>

            {/* Notifications Drawer */}
            <AnimatePresence>
              {notifOpen && (
                <motion.div
                  initial={{ opacity: 0, y: 8, scale: 0.96 }}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, y: 8, scale: 0.96 }}
                  transition={{ duration: 0.18 }}
                  className="absolute right-0 mt-2 w-80 bg-white border border-slate-200 rounded-3xl shadow-xl shadow-slate-900/10 p-4 space-y-3 z-50"
                >
                  <div className="flex items-center justify-between pb-2 border-b border-slate-100">
                    <div className="flex items-center gap-2">
                      <Bell className="w-4 h-4 text-emerald-600" />
                      <h4 className="text-xs font-bold text-slate-900">Store Alerts</h4>
                    </div>
                    <span className="text-[10px] bg-rose-50 text-rose-600 font-bold px-2 py-0.5 rounded-full border border-rose-200">
                      3 New
                    </span>
                  </div>

                  <div className="space-y-2 max-h-72 overflow-y-auto">
                    {notifications.map((n) => {
                      const Icon = n.icon;
                      return (
                        <div
                          key={n.id}
                          className="p-2.5 rounded-2xl bg-slate-50 border border-slate-100 hover:bg-slate-100/70 transition-all space-y-1 cursor-pointer"
                        >
                          <div className="flex items-start gap-2.5">
                            <div className={`p-1.5 rounded-xl ${n.bg} shrink-0 mt-0.5`}>
                              <Icon className={`w-3.5 h-3.5 ${n.color}`} />
                            </div>
                            <div className="truncate">
                              <p className="text-xs font-bold text-slate-900 leading-tight truncate">
                                {n.title}
                              </p>
                              <p className="text-[11px] text-slate-500 leading-snug line-clamp-2">
                                {n.desc}
                              </p>
                              <p className="text-[10px] text-slate-400 font-mono mt-1">{n.time}</p>
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>

                  <div className="pt-2 border-t border-slate-100 text-center">
                    <button
                      type="button"
                      onClick={() => setNotifOpen(false)}
                      className="text-xs font-bold text-emerald-600 hover:text-emerald-700 cursor-pointer"
                    >
                      Dismiss All Alerts
                    </button>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>

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
    </>
  );
}
