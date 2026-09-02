"use client";

import React, { useState } from "react";
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
} from "lucide-react";
import { WebSupplier, WebPurchaseOrder } from "@/types";

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
  const [showAutoPOModal, setShowAutoPOModal] = useState(false);

  const formatRupees = (paise: number) => `₹${(paise / 100).toFixed(2)}`;

  const handleGenerateAutoPO = (supplierId: string) => {
    const sup = suppliers.find((s) => s.id === supplierId);
    if (!sup) return;

    const newPO: WebPurchaseOrder = {
      id: "po_" + Date.now(),
      invoiceNumber: "PO-AUTO-" + String(Date.now()).slice(-4),
      supplierName: sup.name,
      purchaseDate: new Date().toISOString().split("T")[0],
      totalPaise: 1840000,
      status: "draft",
      itemCount: 6,
    };

    setPurchaseOrders([newPO, ...purchaseOrders]);
    setShowAutoPOModal(false);
  };

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />

      <div className="flex-1 flex flex-col min-w-0">
        <Header
          title="Purchases & Supplier Inwarding"
          subtitle="Manage supplier procurement, inward stock updates, and automated reorder purchase orders"
        />

        <main className="p-8 space-y-6 flex-1 overflow-auto">
          {/* Top Suppliers Directory Cards */}
          <div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                <Building2 className="w-4 h-4 text-emerald-600" /> Supplier Directory
              </h3>
              <button
                type="button"
                onClick={() => setShowAutoPOModal(true)}
                className="flex items-center gap-2 px-3.5 py-1.5 rounded-xl text-xs font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 hover:bg-emerald-100 transition-colors"
              >
                <Sparkles className="w-3.5 h-3.5" /> 1-Click Auto-Replenish PO
              </button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {suppliers.map((s) => (
                <div key={s.id} className="p-5 bg-white rounded-2xl border border-slate-200/80 shadow-xs space-y-3">
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
                    {s.gstin && <div className="text-[10px] text-slate-400">GSTIN: {s.gstin}</div>}
                  </div>

                  <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-xs">
                    <span className="text-slate-500">Payable Due:</span>
                    <span
                      className={`font-bold font-mono ${
                        s.pendingBalancePaise > 0 ? "text-rose-600" : "text-emerald-600"
                      }`}
                    >
                      {formatRupees(s.pendingBalancePaise)}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Inward Purchase Orders Table */}
          <div className="bg-white rounded-2xl border border-slate-200/80 shadow-xs space-y-4 p-6">
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
              <div>
                <h4 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <FileSpreadsheet className="w-4 h-4 text-emerald-600" /> Purchase Orders & Inward Log
                </h4>
                <p className="text-xs text-slate-500">Inwarded goods automatically update stock & weighted average cost</p>
              </div>

              <button
                type="button"
                className="flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold text-white bg-slate-900 hover:bg-slate-800 transition-all"
              >
                <Plus className="w-4 h-4" /> Record Inward Invoice
              </button>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase">
                    <th className="py-3 px-3">PO / Invoice No</th>
                    <th className="py-3 px-3">Supplier</th>
                    <th className="py-3 px-3">Order Date</th>
                    <th className="py-3 px-3 text-center">Items Count</th>
                    <th className="py-3 px-3 text-right">Total Inward Value</th>
                    <th className="py-3 px-3 text-center">Status</th>
                    <th className="py-3 px-3 text-center">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {purchaseOrders.map((po) => (
                    <tr key={po.id} className="hover:bg-slate-50/50">
                      <td className="py-3 px-3 font-mono font-bold text-slate-900">{po.invoiceNumber}</td>
                      <td className="py-3 px-3 text-slate-700">{po.supplierName}</td>
                      <td className="py-3 px-3 text-slate-500">{po.purchaseDate}</td>
                      <td className="py-3 px-3 text-center font-mono">{po.itemCount} SKUs</td>
                      <td className="py-3 px-3 text-right font-mono font-bold text-slate-900">
                        {formatRupees(po.totalPaise)}
                      </td>
                      <td className="py-3 px-3 text-center">
                        {po.status === "received" && (
                          <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                            ✓ Stock Inwarded
                          </span>
                        )}
                        {po.status === "ordered" && (
                          <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-amber-50 text-amber-700 border border-amber-200">
                            ⏳ In-Transit
                          </span>
                        )}
                        {po.status === "draft" && (
                          <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-slate-100 text-slate-700 border border-slate-200">
                            📝 Draft PO
                          </span>
                        )}
                      </td>
                      <td className="py-3 px-3 text-center">
                        <button
                          type="button"
                          className="px-2.5 py-1 rounded-lg text-[10px] font-bold bg-slate-100 text-slate-700 hover:bg-slate-200 transition-colors"
                        >
                          View Details
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </main>
      </div>

      {/* Auto PO Modal */}
      {showAutoPOModal && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="bg-white w-full max-w-md rounded-2xl shadow-2xl border border-slate-200 overflow-hidden">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="p-2 bg-emerald-100 text-emerald-700 rounded-xl">
                  <Sparkles className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-slate-900 text-base">Generate Auto-Replenish PO</h3>
                  <p className="text-xs text-slate-500">Draft PO based on current sales velocity &amp; safety stock</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setShowAutoPOModal(false)}
                className="text-slate-400 hover:text-slate-700"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-6 space-y-4 text-xs">
              <p className="text-slate-600 font-medium">
                Select a distributor to automatically add all SKUs currently breaching their minimum safety threshold:
              </p>

              <div className="space-y-2">
                {suppliers.map((s) => (
                  <button
                    key={s.id}
                    type="button"
                    onClick={() => handleGenerateAutoPO(s.id)}
                    className="w-full p-3.5 rounded-xl border border-slate-200 hover:border-emerald-500 hover:bg-emerald-50/50 text-left transition-all flex items-center justify-between group"
                  >
                    <div>
                      <p className="font-bold text-slate-900 group-hover:text-emerald-800">{s.name}</p>
                      <p className="text-[11px] text-slate-500">{s.contactPerson} • {s.phone}</p>
                    </div>
                    <ArrowDownToLine className="w-4 h-4 text-slate-400 group-hover:text-emerald-600" />
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
