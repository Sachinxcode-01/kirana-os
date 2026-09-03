"use client";

/**
 * KiranaOS Client-Side IndexedDB Offline Database
 * Provides rock-solid persistence for draft carts, finalized bills, and offline mutations.
 */

const DB_NAME = "kirana_offline_db";
const DB_VERSION = 1;

export interface OfflineSyncItem {
  id: string;
  type: "CREATE_BILL" | "RECORD_PAYMENT" | "UPDATE_CUSTOMER";
  payload: any;
  timestamp: number;
  retryCount: number;
  status: "PENDING" | "SYNCING" | "FAILED";
  idempotencyKey: string;
}

class OfflineSyncDB {
  private dbPromise: Promise<IDBDatabase> | null = null;

  private getDB(): Promise<IDBDatabase> {
    if (typeof window === "undefined") {
      return Promise.reject(new Error("IndexedDB is not available server-side"));
    }

    if (!this.dbPromise) {
      this.dbPromise = new Promise((resolve, reject) => {
        const request = window.indexedDB.open(DB_NAME, DB_VERSION);

        request.onupgradeneeded = (event) => {
          const db = (event.target as IDBOpenDBRequest).result;

          // 1. Sync Queue Object Store
          if (!db.objectStoreNames.contains("sync_queue")) {
            const syncStore = db.createObjectStore("sync_queue", { keyPath: "id" });
            syncStore.createIndex("status", "status", { unique: false });
            syncStore.createIndex("timestamp", "timestamp", { unique: false });
          }

          // 2. Offline Bills Store
          if (!db.objectStoreNames.contains("offline_bills")) {
            const billStore = db.createObjectStore("offline_bills", { keyPath: "id" });
            billStore.createIndex("timestamp", "timestamp", { unique: false });
          }

          // 3. Draft Carts Store
          if (!db.objectStoreNames.contains("draft_carts")) {
            db.createObjectStore("draft_carts", { keyPath: "id" });
          }
        };

        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
    }

    return this.dbPromise;
  }

  // --- Sync Queue Operations ---

  public async enqueue(
    type: OfflineSyncItem["type"],
    payload: any
  ): Promise<OfflineSyncItem> {
    const db = await this.getDB();
    const item: OfflineSyncItem = {
      id: `op-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
      type,
      payload,
      timestamp: Date.now(),
      retryCount: 0,
      status: "PENDING",
      idempotencyKey: `idemp-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`,
    };

    return new Promise((resolve, reject) => {
      const tx = db.transaction("sync_queue", "readwrite");
      const store = tx.objectStore("sync_queue");
      const req = store.add(item);
      req.onsuccess = () => resolve(item);
      req.onerror = () => reject(req.error);
    });
  }

  public async getPendingQueue(): Promise<OfflineSyncItem[]> {
    const db = await this.getDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction("sync_queue", "readonly");
      const store = tx.objectStore("sync_queue");
      const req = store.getAll();
      req.onsuccess = () => {
        const all = req.result as OfflineSyncItem[];
        resolve(all.filter((i) => i.status === "PENDING" || i.status === "FAILED"));
      };
      req.onerror = () => reject(req.error);
    });
  }

  public async getPendingCount(): Promise<number> {
    const items = await this.getPendingQueue();
    return items.length;
  }

  public async markItemStatus(
    id: string,
    status: OfflineSyncItem["status"],
    incrementRetry = false
  ): Promise<void> {
    const db = await this.getDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction("sync_queue", "readwrite");
      const store = tx.objectStore("sync_queue");
      const req = store.get(id);

      req.onsuccess = () => {
        const item = req.result as OfflineSyncItem | undefined;
        if (item) {
          item.status = status;
          if (incrementRetry) item.retryCount += 1;
          store.put(item);
          resolve();
        } else {
          resolve();
        }
      };
      req.onerror = () => reject(req.error);
    });
  }

  public async removeQueueItem(id: string): Promise<void> {
    const db = await this.getDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction("sync_queue", "readwrite");
      const store = tx.objectStore("sync_queue");
      const req = store.delete(id);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  }

  // --- Draft Cart Operations ---

  public async saveDraftCart(cartItems: any[]): Promise<void> {
    const db = await this.getDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction("draft_carts", "readwrite");
      const store = tx.objectStore("draft_carts");
      const req = store.put({ id: "active_counter_cart", items: cartItems, updatedAt: Date.now() });
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  }

  public async getDraftCart(): Promise<any[] | null> {
    const db = await this.getDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction("draft_carts", "readonly");
      const store = tx.objectStore("draft_carts");
      const req = store.get("active_counter_cart");
      req.onsuccess = () => {
        if (req.result && Array.isArray(req.result.items)) {
          resolve(req.result.items);
        } else {
          resolve(null);
        }
      };
      req.onerror = () => reject(req.error);
    });
  }

  public async clearDraftCart(): Promise<void> {
    const db = await this.getDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction("draft_carts", "readwrite");
      const store = tx.objectStore("draft_carts");
      const req = store.delete("active_counter_cart");
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  }
}

export const offlineSyncDb = new OfflineSyncDB();
