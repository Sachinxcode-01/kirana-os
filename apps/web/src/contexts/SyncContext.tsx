"use client";

import React, { createContext, useContext, useState, useEffect, useCallback } from "react";
import { offlineSyncDb, OfflineSyncItem } from "@/utils/offlineSyncDb";
import { posAudio } from "@/utils/audioFeedback";

interface SyncContextType {
  isOnline: boolean;
  pendingCount: number;
  isSyncing: boolean;
  syncNow: () => Promise<void>;
  enqueueBill: (billData: any) => Promise<OfflineSyncItem>;
  saveCartDraft: (cartItems: any[]) => Promise<void>;
  loadCartDraft: () => Promise<any[] | null>;
  clearCartDraft: () => Promise<void>;
}

const SyncContext = createContext<SyncContextType | undefined>(undefined);

export function SyncProvider({ children }: { children: React.ReactNode }) {
  const [isOnline, setIsOnline] = useState<boolean>(true);
  const [pendingCount, setPendingCount] = useState<number>(0);
  const [isSyncing, setIsSyncing] = useState<boolean>(false);

  const refreshPendingCount = useCallback(async () => {
    try {
      const count = await offlineSyncDb.getPendingCount();
      setPendingCount(count);
    } catch {
      // IndexedDB fallback
    }
  }, []);

  const syncNow = useCallback(async () => {
    if (!navigator.onLine || isSyncing) return;

    try {
      setIsSyncing(true);
      const queue = await offlineSyncDb.getPendingQueue();

      if (queue.length === 0) {
        setIsSyncing(false);
        return;
      }

      let syncedCount = 0;

      for (const item of queue) {
        await offlineSyncDb.markItemStatus(item.id, "SYNCING");

        try {
          if (item.type === "CREATE_BILL") {
            const res = await fetch("/api/bills", {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                "x-idempotency-key": item.idempotencyKey,
              },
              body: JSON.stringify(item.payload),
            });

            if (res.ok) {
              await offlineSyncDb.removeQueueItem(item.id);
              syncedCount += 1;
            } else {
              await offlineSyncDb.markItemStatus(item.id, "FAILED", true);
            }
          } else {
            // General mutation fallback
            await offlineSyncDb.removeQueueItem(item.id);
            syncedCount += 1;
          }
        } catch {
          await offlineSyncDb.markItemStatus(item.id, "FAILED", true);
        }
      }

      await refreshPendingCount();

      if (syncedCount > 0) {
        posAudio.playSuccessChime();
      }
    } finally {
      setIsSyncing(false);
    }
  }, [isSyncing, refreshPendingCount]);

  useEffect(() => {
    if (typeof window === "undefined") return;

    setIsOnline(navigator.onLine);
    refreshPendingCount();

    const handleOnline = () => {
      setIsOnline(true);
      syncNow();
    };

    const handleOffline = () => {
      setIsOnline(false);
      posAudio.playWarningBuzzer();
    };

    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);

    // Polling interval to check pending count & re-sync
    const pollInterval = setInterval(() => {
      refreshPendingCount();
      if (navigator.onLine && pendingCount > 0 && !isSyncing) {
        syncNow();
      }
    }, 15000);

    return () => {
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
      clearInterval(pollInterval);
    };
  }, [pendingCount, isSyncing, refreshPendingCount, syncNow]);

  const enqueueBill = useCallback(
    async (billData: any): Promise<OfflineSyncItem> => {
      const item = await offlineSyncDb.enqueue("CREATE_BILL", billData);
      await refreshPendingCount();

      // If online, attempt immediate sync in background
      if (navigator.onLine) {
        syncNow();
      }

      return item;
    },
    [refreshPendingCount, syncNow]
  );

  const saveCartDraft = useCallback(async (cartItems: any[]) => {
    try {
      await offlineSyncDb.saveDraftCart(cartItems);
    } catch {
      // Storage fallback
    }
  }, []);

  const loadCartDraft = useCallback(async () => {
    try {
      return await offlineSyncDb.getDraftCart();
    } catch {
      return null;
    }
  }, []);

  const clearCartDraft = useCallback(async () => {
    try {
      await offlineSyncDb.clearDraftCart();
    } catch {
      // Storage fallback
    }
  }, []);

  return (
    <SyncContext.Provider
      value={{
        isOnline,
        pendingCount,
        isSyncing,
        syncNow,
        enqueueBill,
        saveCartDraft,
        loadCartDraft,
        clearCartDraft,
      }}
    >
      {children}
    </SyncContext.Provider>
  );
}

export function useSyncEngine() {
  const context = useContext(SyncContext);
  if (!context) {
    throw new Error("useSyncEngine must be used within a SyncProvider");
  }
  return context;
}
