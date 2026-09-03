"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Sidebar } from "@/components/layout/Sidebar";
import { Header } from "@/components/layout/Header";
import {
  Truck,
  Plus,
  Search,
  Building2,
  FileSpreadsheet,
  CheckCircle2,
  Sparkles,
  Phone,
  Clock,
  ArrowDownToLine,
  X,
  CreditCard,
  FileText,
  BadgePercent,
  Check,
  PackageCheck,
} from "lucide-react";
import { WebSupplier, WebPurchaseOrder } from "@/types";
import { Supplier360Drawer } from "@/components/suppliers/Supplier360Drawer";

const INITIAL_SUPPLIERS: WebSupplier[] = [
  {
    id: "sup1",
    name: "ITC Distribution Bangalore Central",
    contactPerson: "Sanjay Hegde",
    phone: "9845012345",
    email: "itc.blr@dist.com",
    gstin: "29AABCI1234F1Z1",
    pendingBalancePaise: 4500000,
  },
  {
    id: "sup2",
    name: "Amul Dairy Agencies Karnataka",
    contactPerson: "Mahesh Gowda",
    phone: "9845098765",
    email: "amul.blr@agencies.in",
    gstin: "29AABCA5678K1Z3",
    pendingBalancePaise: 1200000,
  },
  {
    id: "sup3",
    name: "Hindustan Unilever Metro Depot",
    contactPerson: "Kiran Rao",
    phone: "9845055555",
    email: "hul.metro@dist.in",
    gstin: "29AABCH9999M1Z8",
    pendingBalancePaise: 0,
  },
];

const INITIAL_POS: WebPurchaseOrder[] = [
  {
    id: "po1",
    invoiceNumber: "PO-2026-0042",
    supplierName: "ITC Distribution Bangalore Central",
    purchaseDate: "2026-09-01",
    totalPaise: 2850000,
    status: "received",
    itemCount: 14,
  },
  {
    id: "po2",
    invoiceNumber: "PO-2026-0043",
    supplierName: "Amul Dairy Agencies Karnataka",
    purchaseDate: "2026-09-02",
    totalPaise: 1650000,
    status: "ordered",
    itemCount: 8,
  },
];

export default function PurchasesPage() {
  const [suppliers, setSuppliers] = useState<WebSupplier[]>(INITIAL_SUPPLIERS);
  const [purchaseOrders, setPurchaseOrders] = useState<WebPurchaseOrder[]>(INITIAL_POS);
  const [search, setSearch] = useState("");

  // Modals state
  const [showAutoPOModal, setShowAutoPOModal] = useState(false);
  const [showNewInwardModal, setShowNewInwardModal] = useState(false);
  const [payingSupplier, setPayingSupplier] = useState<WebSupplier | null>(null);
  const [selectedSupplierForDrawer, setSelectedSupplierForDrawer] = useState<WebSupplier | null>(null);
  const [payAmount, setPayAmount] = useState("");
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  // New PO form state
  const [poSupplier, setPoSupplier] = useState(INITIAL_SUPPLIERS[0].name);
  const [poInvNo, setPoInvNo] = useState("INV-" + String(Date.now()).slice(-6));
  const [poTotalRupees, setPoTotalRupees] = useState("15000.00");
  const [poItemCount, setPoItemCount] = useState("10");

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

  const formatRupees = (paise: number) =>
    `₹${(paise / 100).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

  const handleGenerateAutoPO = (supplierId: string) => {
    const sup = suppliers.find((s) => s.id === supplierId);
    if (!sup) return;

    const newPO: WebPurchaseOrder = {
      id: "po_" + Date.now(),
      invoiceNumber: "PO-AUTO-" + String(Date.now()).slice(-4),
      supplierName: sup.name,
      purchaseDate: new Date().toISOString().split("T")[0],
      totalPaise: 1840000,
      status: "ordered",
      itemCount: 6,
    };

    setPurchaseOrders([newPO, ...purchaseOrders]);
    setShowAutoPOModal(false);
    showToast(`Generated automated replenishment PO for ${sup.name}`);
  };

  const handleCreateInwardPO = (e: React.FormEvent) => {
    e.preventDefault();
    const newPO: WebPurchaseOrder = {
      id: "po_" + Date.now(),
      invoiceNumber: poInvNo.trim(),
      supplierName: poSupplier,
      purchaseDate: new Date().toISOString().split("T")[0],
      totalPaise: Math.round(parseFloat(poTotalRupees || "0") * 100),
      status: "ordered",
      itemCount: parseInt(poItemCount || "1", 10),
    };

    setPurchaseOrders([newPO, ...purchaseOrders]);
    setShowNewInwardModal(false);
    showToast(`Inward Purchase Order ${newPO.invoiceNumber} recorded.`);
  };

  const handleMarkReceived = (poId: string) => {
    setPurchaseOrders(
      purchaseOrders.map((po) =>
        po.id === poId ? { ...po, status: "received" } : po
      )
    );
    showToast("Shipment marked as received. Catalog inventory updated!");
  };

  const handlePaySupplier = (e: React.FormEvent) => {
    e.preventDefault();
    if (!payingSupplier || !payAmount) return;

    const paidPaise = Math.round(parseFloat(payAmount) * 100);
    setSuppliers(
      suppliers.map((s) =>
        s.id === payingSupplier.id
          ? { ...s, pendingBalancePaise: Math.max(0, s.pendingBalancePaise - paidPaise) }
          : s
      )
    );

    showToast(`Payment of ${formatRupees(paidPaise)} sent to ${payingSupplier.name}`);
    setPayingSupplier(null);
    setPayAmount("");
  };

  return (
    <div className="flex min-h-screen bg-slate-50 relative overflow-hidden">
      {/* Background glow */}
      <div className="absolute top-0 right-0 w-96 h-96 bg-teal-400/10 rounded-full blur-3xl pointer-events-none"></div>

      <Sidebar isOpen={mobileNavOpen} onClose={() => setMobileNavOpen(false)} />

      <div className="flex-1 flex flex-col min-w-0 z-10">
        <Header
          title="Purchases & Supplier Inwarding"
          subtitle="Manage supplier procurement, inward stock updates, and automated reorder purchase orders"
          onMenuClick={() => setMobileNavOpen(true)}
        />

        <main className="p-8 space-y-6 flex-1 overflow-auto">
          {/* Notification Toast */}
          <AnimatePresence>
            {toastMessage && (
              <motion.div
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                className="p-3.5 bg-emerald-600 text-white rounded-2xl shadow-lg flex items-center justify-between gap-3 text-xs font-bold"
              >
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-emerald-200" />
                  <span>{toastMessage}</span>
                </div>
                <button
                  type="button"
                  onClick={() => setToastMessage(null)}
                  className="p-1 hover:bg-emerald-700 rounded-lg cursor-pointer"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Top Suppliers Directory Cards */}
          <div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                <Building2 className="w-4 h-4 text-emerald-600" /> Supplier &amp; Distributor Directory
              </h3>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => setShowAutoPOModal(true)}
                  className="flex items-center gap-2 px-3.5 py-1.5 rounded-xl text-xs font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 hover:bg-emerald-100 transition-colors cursor-pointer"
                >
                  <Sparkles className="w-3.5 h-3.5 text-amber-500" /> 1-Click Auto-Replenish PO
                </button>
                <button
                  type="button"
                  onClick={() => setShowNewInwardModal(true)}
                  className="flex items-center gap-2 px-3.5 py-1.5 rounded-xl text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 transition-colors cursor-pointer shadow-sm shadow-emerald-950/20"
                >
                  <Plus className="w-3.5 h-3.5" /> Record Inward Delivery
                </button>
              </div>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {suppliers.map((s) => (
                <div key={s.id} className="p-5 glass-card rounded-2xl shadow-xs space-y-3">
                  <div className="flex items-start justify-between">
                    <div>
                      <h4 className="font-bold text-slate-900 text-sm leading-snug">{s.name}</h4>
                      <p className="text-xs text-slate-500 font-medium">Contact: {s.contactPerson}</p>
                    </div>
                    <div className="p-2 bg-slate-100 rounded-xl text-slate-600">
                      <Truck className="w-4 h-4" />
                    </div>
                  </div>

                  <div className="text-xs text-slate-600 space-y-1 font-mono">
                    <div className="flex items-center gap-1 text-[11px]">
                      <Phone className="w-3 h-3 text-slate-400" /> +91 {s.phone}
                    </div>
                    <div className="text-[11px] text-slate-400">GSTIN: {s.gstin}</div>
                  </div>

                  <div className="pt-2 border-t border-slate-100 flex items-center justify-between">
                    <div>
                      <p className="text-[10px] text-slate-400 uppercase font-bold">Pending Dues</p>
                      <p className="text-xs font-bold font-mono text-slate-900">
                        {formatRupees(s.pendingBalancePaise)}
                      </p>
                    </div>
                    <div className="flex items-center gap-1.5">
                      <button
                        type="button"
                        onClick={() => setSelectedSupplierForDrawer(s)}
                        className="px-2 py-1 rounded-lg text-xs font-bold text-slate-700 bg-slate-100 hover:bg-slate-200 border border-slate-200 transition-colors cursor-pointer"
                      >
                        360° Profile
                      </button>
                      {s.pendingBalancePaise > 0 ? (
                        <button
                          type="button"
                          onClick={() => {
                            setPayingSupplier(s);
                            setPayAmount((s.pendingBalancePaise / 100).toFixed(2));
                          }}
                          className="px-2.5 py-1 rounded-lg text-xs font-bold text-emerald-700 bg-emerald-50 hover:bg-emerald-100 border border-emerald-200 transition-colors cursor-pointer"
                        >
                          Pay
                        </button>
                      ) : (
                        <span className="px-2 py-0.5 rounded-md text-[10px] font-bold bg-slate-100 text-slate-500">
                          Cleared
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Inward Orders Ledger */}
          <div className="glass-card rounded-2xl shadow-xs overflow-hidden">
            <div className="p-4 border-b border-slate-200/80 flex items-center justify-between bg-slate-50/60">
              <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                <FileSpreadsheet className="w-4 h-4 text-emerald-600" /> Recent Purchase Orders &amp; Inward Invoices
              </h3>
              <span className="text-xs text-slate-500 font-medium">Auto-ITC Reconciliation</span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="bg-slate-100/70 border-b border-slate-200 text-[11px] font-bold text-slate-600 uppercase tracking-wider">
                    <th className="py-3.5 px-4">PO / Invoice #</th>
                    <th className="py-3.5 px-4">Supplier</th>
                    <th className="py-3.5 px-4">Purchase Date</th>
                    <th className="py-3.5 px-4 text-center">Items Inwarded</th>
                    <th className="py-3.5 px-4 text-right">Invoice Total</th>
                    <th className="py-3.5 px-4 text-center">Status</th>
                    <th className="py-3.5 px-4 text-center">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-xs text-slate-700 font-medium">
                  {purchaseOrders.map((po) => (
                    <tr key={po.id} className="hover:bg-slate-50/70 transition-colors">
                      <td className="py-3 px-4 font-mono font-bold text-slate-900">
                        {po.invoiceNumber}
                      </td>
                      <td className="py-3 px-4 text-slate-900 font-semibold">{po.supplierName}</td>
                      <td className="py-3 px-4 font-mono text-slate-500">{po.purchaseDate}</td>
                      <td className="py-3 px-4 text-center font-mono">{po.itemCount} SKUs</td>
                      <td className="py-3 px-4 text-right font-mono font-bold text-slate-900">
                        {formatRupees(po.totalPaise)}
                      </td>
                      <td className="py-3 px-4 text-center">
                        {po.status === "received" ? (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-800 border border-emerald-200">
                            <CheckCircle2 className="w-3 h-3 text-emerald-600" /> Stock Inwarded
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold bg-amber-50 text-amber-800 border border-amber-200">
                            <Clock className="w-3 h-3 text-amber-600" /> Ordered / In Transit
                          </span>
                        )}
                      </td>
                      <td className="py-3 px-4 text-center">
                        {po.status !== "received" ? (
                          <button
                            type="button"
                            onClick={() => handleMarkReceived(po.id)}
                            className="px-2.5 py-1 rounded-lg text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 transition-colors cursor-pointer flex items-center gap-1 mx-auto"
                          >
                            <PackageCheck className="w-3.5 h-3.5" />
                            <span>Mark Received</span>
                          </button>
                        ) : (
                          <span className="text-[11px] text-slate-400 font-semibold">Verified</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="p-4 border-t border-slate-100 bg-slate-50/50 flex items-center justify-between text-xs text-slate-500">
              <span>Showing {purchaseOrders.length} inward procurement transactions</span>
              <span className="font-semibold text-emerald-700">Input Tax Credit (ITC) Auto-Tracked</span>
            </div>
          </div>
        </main>
      </div>

      {/* Modal 1: 1-Click Auto PO */}
      <AnimatePresence>
        {showAutoPOModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl space-y-4"
            >
              <div className="flex items-center justify-between pb-2 border-b border-slate-100">
                <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <Sparkles className="w-4 h-4 text-amber-500" /> 1-Click Replenishment Reorder
                </h3>
                <button
                  type="button"
                  onClick={() => setShowAutoPOModal(false)}
                  className="text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <p className="text-xs text-slate-600">
                KiranaOS analyzes current stock deficits against safety stock limits to calculate purchase orders automatically.
              </p>

              <div className="space-y-2">
                {suppliers.map((s) => (
                  <div
                    key={s.id}
                    className="p-3 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-2xl flex items-center justify-between cursor-pointer transition-colors"
                    onClick={() => handleGenerateAutoPO(s.id)}
                  >
                    <div>
                      <h5 className="font-bold text-xs text-slate-900">{s.name}</h5>
                      <span className="text-[11px] text-slate-500 font-mono">GSTIN: {s.gstin}</span>
                    </div>
                    <button
                      type="button"
                      className="px-3 py-1 bg-emerald-600 text-white rounded-xl text-xs font-bold shadow-xs hover:bg-emerald-700 cursor-pointer"
                    >
                      Generate PO
                    </button>
                  </div>
                ))}
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Modal 2: Record New Inward Invoice */}
      <AnimatePresence>
        {showNewInwardModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl space-y-4"
            >
              <div className="flex items-center justify-between pb-2 border-b border-slate-100">
                <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <Truck className="w-4 h-4 text-emerald-600" /> Record Inward Goods Delivery
                </h3>
                <button
                  type="button"
                  onClick={() => setShowNewInwardModal(false)}
                  className="text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <form onSubmit={handleCreateInwardPO} className="space-y-3 text-xs">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Distributor / Supplier</label>
                  <select
                    value={poSupplier}
                    onChange={(e) => setPoSupplier(e.target.value)}
                    className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200"
                  >
                    {suppliers.map((s) => (
                      <option key={s.id} value={s.name}>{s.name}</option>
                    ))}
                  </select>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="font-bold text-slate-700 block mb-1">Supplier Bill #</label>
                    <input
                      type="text"
                      required
                      value={poInvNo}
                      onChange={(e) => setPoInvNo(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono"
                    />
                  </div>
                  <div>
                    <label className="font-bold text-slate-700 block mb-1">SKU Count</label>
                    <input
                      type="number"
                      min="1"
                      required
                      value={poItemCount}
                      onChange={(e) => setPoItemCount(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono"
                    />
                  </div>
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">Total Inward Bill Amount (₹)</label>
                  <input
                    type="number"
                    step="0.01"
                    required
                    value={poTotalRupees}
                    onChange={(e) => setPoTotalRupees(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 font-mono font-bold text-center text-lg text-slate-900"
                  />
                </div>

                <div className="pt-2 border-t border-slate-100 flex items-center justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => setShowNewInwardModal(false)}
                    className="px-3.5 py-1.5 rounded-xl text-slate-600 hover:bg-slate-100 font-semibold cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold cursor-pointer"
                  >
                    Confirm Inward Bill
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Modal 3: Pay Supplier */}
      <AnimatePresence>
        {payingSupplier && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-sm bg-white rounded-3xl p-6 shadow-2xl space-y-4"
            >
              <div className="flex items-center justify-between pb-2 border-b border-slate-100">
                <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <CreditCard className="w-4 h-4 text-emerald-600" /> Settle Supplier Outstanding
                </h3>
                <button
                  type="button"
                  onClick={() => setPayingSupplier(null)}
                  className="text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 text-xs space-y-1">
                <p className="font-bold text-slate-900">{payingSupplier.name}</p>
                <p className="text-slate-500">
                  Total Dues: <strong className="text-slate-900 font-mono font-bold">{formatRupees(payingSupplier.pendingBalancePaise)}</strong>
                </p>
              </div>

              <form onSubmit={handlePaySupplier} className="space-y-4 text-xs">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Amount to Pay (₹)</label>
                  <input
                    type="number"
                    step="0.01"
                    min="1"
                    required
                    value={payAmount}
                    onChange={(e) => setPayAmount(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 font-mono font-bold text-center text-lg text-slate-900 focus:bg-white focus:outline-none focus:border-emerald-500"
                  />
                </div>

                <div className="pt-2 border-t border-slate-100 flex items-center justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => setPayingSupplier(null)}
                    className="px-3.5 py-1.5 rounded-xl text-slate-600 hover:bg-slate-100 font-semibold cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold cursor-pointer"
                  >
                    Confirm Payment
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
      {/* Phase 22: Supplier 360° Procurement Drawer */}
      <Supplier360Drawer
        supplier={selectedSupplierForDrawer}
        isOpen={Boolean(selectedSupplierForDrawer)}
        onClose={() => setSelectedSupplierForDrawer(null)}
        onRecordPayment={(sup) => {
          setPayingSupplier(sup);
          setPayAmount((sup.pendingBalancePaise / 100).toFixed(2));
        }}
      />
    </div>
  );
}
