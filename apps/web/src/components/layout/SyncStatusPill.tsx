"use client";

import React from "react";
import { RefreshCw, Wifi, WifiOff } from "lucide-react";
import { useSyncEngine } from "@/contexts/SyncContext";

export function SyncStatusPill() {
  const { isOnline, pendingCount, isSyncing, syncNow } = useSyncEngine();

  if (!isOnline) {
    return (
      <div
        className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-rose-950/80 border border-rose-800/80 text-rose-300 text-xs font-mono font-bold shadow-xs select-none"
        title="Internet disconnected. Local IndexedDB storage active. All bills are protected."
      >
        <span className="w-2 h-2 rounded-full bg-rose-500 animate-pulse"></span>
        <WifiOff className="w-3.5 h-3.5 text-rose-400" />
        <span>Offline Mode</span>
        {pendingCount > 0 && (
          <span className="px-1.5 py-0.2 rounded-full bg-rose-900 text-[10px] text-rose-200">
            {pendingCount} queued
          </span>
        )}
      </div>
    );
  }

  if (pendingCount > 0) {
    return (
      <button
        type="button"
        onClick={() => syncNow()}
        disabled={isSyncing}
        className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-amber-950/80 hover:bg-amber-900/80 border border-amber-800/80 text-amber-300 text-xs font-mono font-bold shadow-xs cursor-pointer transition-all select-none"
        title="Click to sync offline transactions to cloud database"
      >
        <RefreshCw className={`w-3.5 h-3.5 text-amber-400 ${isSyncing ? "animate-spin" : ""}`} />
        <span>{isSyncing ? "Syncing..." : `${pendingCount} Pending`}</span>
      </button>
    );
  }

  return (
    <div
      className="hidden sm:flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-950/60 border border-emerald-800/60 text-emerald-300 text-xs font-mono font-semibold select-none shadow-xs"
      title="Live cloud synchronization active via Supabase & PostgreSQL"
    >
      <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
      <Wifi className="w-3.5 h-3.5 text-emerald-400" />
      <span>Cloud Synced</span>
    </div>
  );
}
