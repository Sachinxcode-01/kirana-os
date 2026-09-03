"use client";

import React, { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  Wifi,
  WifiOff,
  RefreshCw,
  Database,
  Cloud,
  CheckCircle2,
  HardDrive,
  ShieldCheck,
  Zap,
} from "lucide-react";
import { posAudio } from "@/utils/audioFeedback";

export function SyncStatusPill() {
  const [isOnline, setIsOnline] = useState<boolean>(true);
  const [isSyncing, setIsSyncing] = useState<boolean>(false);
  const [latencyMs, setLatencyMs] = useState<number>(14);
  const [pendingQueueCount, setPendingQueueCount] = useState<number>(0);
  const [lastSyncTime, setLastSyncTime] = useState<string>("Just now");
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (typeof window !== "undefined") {
      setIsOnline(navigator.onLine);

      const handleOnline = () => {
        setIsOnline(true);
        triggerSync(true);
      };

      const handleOffline = () => {
        setIsOnline(false);
        setPendingQueueCount((prev) => (prev === 0 ? 2 : prev));
        posAudio.playWarningBuzzer();
      };

      window.addEventListener("online", handleOnline);
      window.addEventListener("offline", handleOffline);

      return () => {
        window.removeEventListener("online", handleOnline);
        window.removeEventListener("offline", handleOffline);
      };
    }
  }, []);

  // Close popover when clicking outside
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const triggerSync = async (automatic: boolean = false) => {
    if (isSyncing) return;
    setIsSyncing(true);

    const start = Date.now();
    try {
      // Simulate/probe round-trip
      await new Promise((res) => setTimeout(res, 800));
      setLatencyMs(Math.max(8, Date.now() - start - 780));
      setPendingQueueCount(0);
      setLastSyncTime(
        new Date().toLocaleTimeString("en-IN", {
          hour: "2-digit",
          minute: "2-digit",
          second: "2-digit",
          hour12: true,
        })
      );
      if (!automatic) {
        posAudio.playSuccessChime();
      }
    } finally {
      setIsSyncing(false);
    }
  };

  return (
    <div className="relative" ref={dropdownRef}>
      {/* Clickable Pill Trigger */}
      <motion.button
        whileHover={{ scale: 1.02 }}
        whileTap={{ scale: 0.98 }}
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold border transition-all cursor-pointer shadow-xs ${
          !isOnline
            ? "bg-amber-50 border-amber-300 text-amber-900"
            : isSyncing
            ? "bg-teal-50 border-teal-300 text-teal-800"
            : "bg-emerald-50 border-emerald-200 text-emerald-800"
        }`}
        title="Network & Cloud Sync Telemetry"
      >
        {/* Animated Status Dot */}
        <span className="relative flex h-2 w-2">
          {isOnline && (
            <span
              className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 ${
                isSyncing ? "bg-teal-400" : "bg-emerald-400"
              }`}
            />
          )}
          <span
            className={`relative inline-flex rounded-full h-2 w-2 ${
              !isOnline ? "bg-amber-500" : isSyncing ? "bg-teal-500" : "bg-emerald-600"
            }`}
          />
        </span>

        {/* Status Icon */}
        {!isOnline ? (
          <WifiOff className="w-3.5 h-3.5 text-amber-700" />
        ) : isSyncing ? (
          <RefreshCw className="w-3.5 h-3.5 text-teal-600 animate-spin" />
        ) : (
          <Wifi className="w-3.5 h-3.5 text-emerald-600" />
        )}

        {/* Label */}
        <span>
          {!isOnline
            ? "Offline Mode (Local)"
            : isSyncing
            ? "Syncing Queue..."
            : `Synced (${latencyMs}ms)`}
        </span>

        {pendingQueueCount > 0 && (
          <span className="ml-0.5 px-1.5 py-0.2 text-[10px] font-mono font-black rounded-full bg-amber-200 text-amber-900">
            {pendingQueueCount}
          </span>
        )}
      </motion.button>

      {/* Popover Detail Drawer */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: 8, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 8, scale: 0.96 }}
            transition={{ duration: 0.18 }}
            className="absolute right-0 mt-2 w-80 bg-white/95 backdrop-blur-xl border border-slate-200 rounded-3xl shadow-xl shadow-slate-900/10 p-4 space-y-3 z-50 text-slate-800"
          >
            {/* Header */}
            <div className="flex items-center justify-between pb-2 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <div className="p-1.5 bg-emerald-50 rounded-lg text-emerald-600">
                  <Cloud className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="text-xs font-bold text-slate-900">Sync &amp; Storage Engine</h4>
                  <p className="text-[10px] text-slate-500">Local Drift SQLite + Supabase Cloud</p>
                </div>
              </div>
              <span
                className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${
                  isOnline
                    ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                    : "bg-amber-50 text-amber-700 border-amber-200"
                }`}
              >
                {isOnline ? "Cloud Active" : "Local Drift"}
              </span>
            </div>

            {/* Diagnostic Metrics Grid */}
            <div className="space-y-2 text-xs">
              <div className="p-2.5 bg-slate-50 rounded-2xl border border-slate-100 space-y-1.5">
                <div className="flex items-center justify-between">
                  <span className="text-slate-500 font-medium text-[11px]">Active Engine:</span>
                  <span className="font-bold text-slate-800 flex items-center gap-1">
                    <Database className="w-3 h-3 text-emerald-600" />
                    <span>Supabase PostgreSQL 16</span>
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="text-slate-500 font-medium text-[11px]">Round-Trip Latency:</span>
                  <span className="font-mono font-bold text-emerald-700 text-[11px]">
                    {isOnline ? `${latencyMs} ms (AP-South-1)` : "N/A (Offline)"}
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="text-slate-500 font-medium text-[11px]">Pending Sync Queue:</span>
                  <span className="font-mono font-bold text-slate-900">
                    {pendingQueueCount === 0 ? "0 mutations (Clean)" : `${pendingQueueCount} items queued`}
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <span className="text-slate-500 font-medium text-[11px]">Last Cloud Sync:</span>
                  <span className="font-mono text-slate-600 text-[11px]">{lastSyncTime}</span>
                </div>
              </div>

              {/* Local Resilience Note */}
              <div className="p-2 bg-emerald-50/70 border border-emerald-200/80 rounded-xl text-[11px] text-emerald-800 flex items-start gap-1.5">
                <ShieldCheck className="w-3.5 h-3.5 text-emerald-600 shrink-0 mt-0.5" />
                <span>
                  Offline-First Architecture: Counter will continue billing without internet. All receipts queue locally.
                </span>
              </div>
            </div>

            {/* Force Sync Action Button */}
            <div className="pt-1 border-t border-slate-100">
              <button
                type="button"
                onClick={() => triggerSync(false)}
                disabled={isSyncing || !isOnline}
                className="w-full py-2 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 disabled:opacity-50 text-white text-xs font-bold rounded-xl shadow-sm flex items-center justify-center gap-2 cursor-pointer transition-all"
              >
                <RefreshCw className={`w-3.5 h-3.5 ${isSyncing ? "animate-spin" : ""}`} />
                <span>{isSyncing ? "Synchronizing to Cloud..." : "Force Cloud Sync Now"}</span>
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
