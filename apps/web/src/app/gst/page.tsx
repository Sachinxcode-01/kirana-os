"use client";

import React, { useState } from "react";
import { Sidebar } from "@/components/layout/Sidebar";
import { Header } from "@/components/layout/Header";
import {
  FileText,
  Download,
  Calendar,
  Building,
  CheckCircle2,
  FileSpreadsheet,
  Hash,
  Percent,
} from "lucide-react";

export default function GSTCenterPage() {
  const [period, setPeriod] = useState("Sep 2026 (Monthly)");

  const formatRupees = (paise: number) => `₹${(paise / 100).toFixed(2)}`;

  const taxSlabs = [
    { rate: "0% GST (Nil / Exempted)", taxablePaise: 1850000, cgstPaise: 0, sgstPaise: 0, totalTaxPaise: 0 },
    { rate: "5% GST (Oils & Flours)", taxablePaise: 3200000, cgstPaise: 80000, sgstPaise: 80000, totalTaxPaise: 160000 },
    { rate: "12% GST (Butter & Dairy)", taxablePaise: 1540000, cgstPaise: 92400, sgstPaise: 92400, totalTaxPaise: 184800 },
    { rate: "18% GST (Soaps & Detergents)", taxablePaise: 2460000, cgstPaise: 221400, sgstPaise: 221400, totalTaxPaise: 442800 },
    { rate: "28% GST (Luxury / Beverages)", taxablePaise: 0, cgstPaise: 0, sgstPaise: 0, totalTaxPaise: 0 },
  ];

  const hsnItems = [
    { hsn: "1101", desc: "Wheat Flour / Atta", uqc: "kg", qty: 450, totalValPaise: 1102500, taxPaise: 0, rate: 0.0 },
    { hsn: "1512", desc: "Refined Sunflower Oil", uqc: "L", qty: 240, totalValPaise: 3240000, taxPaise: 154285, rate: 5.0 },
    { hsn: "0405", desc: "Butter & Dairy Spreads", uqc: "packet", qty: 85, totalValPaise: 2337500, taxPaise: 250446, rate: 12.0 },
    { hsn: "3402", desc: "Detergents & Soaps", uqc: "kg", qty: 150, totalValPaise: 2400000, taxPaise: 366101, rate: 18.0 },
  ];

  const totalInvoiceVal = 9050000;
  const totalTaxable = 8262368;
  const totalCGST = 393816;
  const totalSGST = 393816;
  const totalTaxLiability = totalCGST + totalSGST;

  const downloadGSTR1JSON = () => {
    const payload = {
      gstin: "29AAAAA0000A1Z5",
      fp: "092026",
      gt: 90500.0,
      cur_gt: 90500.0,
      b2cs: [
        {
          sply_ty: "INTRA",
          pos: "29",
          typ: "OE",
          txval: 82623.68,
          camt: 3938.16,
          samt: 3938.16,
          csamt: 0.0,
        },
      ],
      hsn: {
        data: hsnItems.map((item, idx) => ({
          num: idx + 1,
          hsn_sc: item.hsn,
          desc: item.desc,
          uqc: item.uqc,
          qty: item.qty,
          val: item.totalValPaise / 100,
          txval: (item.totalValPaise - item.taxPaise) / 100,
          camt: item.taxPaise / 200,
          samt: item.taxPaise / 200,
          csamt: 0.0,
        })),
      },
    };

    const blob = new Blob([JSON.stringify(payload, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `GSTR1_29AAAAA0000A1Z5_SEP2026.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />

      <div className="flex-1 flex flex-col min-w-0">
        <Header
          title="GST Tax Center & GSTR-1 Summaries"
          subtitle="Tax liability aggregation, HSN Table 12 summaries, and one-click GST portal offline exports"
        />

        <main className="p-8 space-y-6 flex-1 overflow-auto">
          {/* GSTIN Business Header */}
          <div className="p-6 bg-gradient-to-tr from-slate-900 to-slate-800 text-white rounded-2xl shadow-md flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div>
              <div className="flex items-center gap-2">
                <Building className="w-5 h-5 text-emerald-400" />
                <h3 className="font-bold text-lg text-white">Sri Lakshmi Provision &amp; Supermarket</h3>
              </div>
              <p className="text-xs text-slate-400 mt-1 font-mono">
                GSTIN: <span className="text-emerald-400 font-bold">29AAAAA0000A1Z5</span> • State: Karnataka (29)
              </p>
            </div>

            <div className="flex items-center gap-3">
              <select
                value={period}
                onChange={(e) => setPeriod(e.target.value)}
                className="text-xs bg-slate-800 text-white border border-slate-700 rounded-xl px-3.5 py-2 font-semibold focus:outline-none focus:border-emerald-500"
              >
                <option value="Sep 2026 (Monthly)">September 2026 (Monthly)</option>
                <option value="Aug 2026 (Monthly)">August 2026 (Monthly)</option>
                <option value="Q2 FY27">Q2 FY 2026-27</option>
              </select>

              <button
                type="button"
                onClick={downloadGSTR1JSON}
                className="flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold text-slate-900 bg-emerald-400 hover:bg-emerald-300 transition-all shadow-sm"
              >
                <Download className="w-4 h-4" /> Export GSTR-1 JSON
              </button>
            </div>
          </div>

          {/* Aggregated Totals Row */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="p-5 bg-white rounded-2xl border border-slate-200/80 shadow-xs">
              <span className="text-xs text-slate-500 font-semibold uppercase">Total Invoiced Sales</span>
              <h4 className="text-2xl font-black font-mono mt-1 text-slate-900">{formatRupees(totalInvoiceVal)}</h4>
              <p className="text-[11px] text-slate-400 mt-1">Gross Consumer Revenue</p>
            </div>

            <div className="p-5 bg-white rounded-2xl border border-slate-200/80 shadow-xs">
              <span className="text-xs text-slate-500 font-semibold uppercase">Taxable Value</span>
              <h4 className="text-2xl font-black font-mono mt-1 text-slate-900">{formatRupees(totalTaxable)}</h4>
              <p className="text-[11px] text-slate-400 mt-1">Excludes GST amount</p>
            </div>

            <div className="p-5 bg-white rounded-2xl border border-slate-200/80 shadow-xs">
              <span className="text-xs text-slate-500 font-semibold uppercase">CGST + SGST (Intra-State)</span>
              <h4 className="text-2xl font-black font-mono mt-1 text-emerald-700">{formatRupees(totalTaxLiability)}</h4>
              <p className="text-[11px] text-emerald-600 font-semibold mt-1">
                CGST: {formatRupees(totalCGST)} | SGST: {formatRupees(totalSGST)}
              </p>
            </div>

            <div className="p-5 bg-white rounded-2xl border border-slate-200/80 shadow-xs">
              <span className="text-xs text-slate-500 font-semibold uppercase">IGST (Inter-State)</span>
              <h4 className="text-2xl font-black font-mono mt-1 text-slate-900">₹0.00</h4>
              <p className="text-[11px] text-slate-400 mt-1">100% Local Retail Transactions</p>
            </div>
          </div>

          {/* Tax Slabs Summary Table */}
          <div className="p-6 bg-white rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
            <h4 className="font-bold text-slate-900 text-sm flex items-center gap-2">
              <Percent className="w-4 h-4 text-emerald-600" /> GST Tax Slabs Breakdown
            </h4>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase">
                    <th className="py-2.5 px-3">Tax Slab &amp; Category</th>
                    <th className="py-2.5 px-3 text-right">Taxable Amount</th>
                    <th className="py-2.5 px-3 text-right">CGST (50%)</th>
                    <th className="py-2.5 px-3 text-right">SGST (50%)</th>
                    <th className="py-2.5 px-3 text-right">Total Tax Liability</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {taxSlabs.map((slab) => (
                    <tr key={slab.rate} className="hover:bg-slate-50/50">
                      <td className="py-2.5 px-3 font-bold text-slate-900">{slab.rate}</td>
                      <td className="py-2.5 px-3 text-right font-mono">{formatRupees(slab.taxablePaise)}</td>
                      <td className="py-2.5 px-3 text-right font-mono text-slate-600">{formatRupees(slab.cgstPaise)}</td>
                      <td className="py-2.5 px-3 text-right font-mono text-slate-600">{formatRupees(slab.sgstPaise)}</td>
                      <td className="py-2.5 px-3 text-right font-mono font-bold text-emerald-700">
                        {formatRupees(slab.totalTaxPaise)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* HSN Summary (Table 12 GSTR-1) */}
          <div className="p-6 bg-white rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
            <h4 className="font-bold text-slate-900 text-sm flex items-center gap-2">
              <Hash className="w-4 h-4 text-emerald-600" /> HSN Summary of Outward Supplies (GSTR-1 Table 12)
            </h4>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase">
                    <th className="py-2.5 px-3">HSN Code</th>
                    <th className="py-2.5 px-3">Description</th>
                    <th className="py-2.5 px-3 text-center">UQC</th>
                    <th className="py-2.5 px-3 text-center">Total Quantity</th>
                    <th className="py-2.5 px-3 text-right">Total Invoice Value</th>
                    <th className="py-2.5 px-3 text-center">GST Rate</th>
                    <th className="py-2.5 px-3 text-right">Tax Collected</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-medium">
                  {hsnItems.map((item) => (
                    <tr key={item.hsn} className="hover:bg-slate-50/50">
                      <td className="py-2.5 px-3 font-mono font-bold text-slate-900">{item.hsn}</td>
                      <td className="py-2.5 px-3 text-slate-700">{item.desc}</td>
                      <td className="py-2.5 px-3 text-center font-mono">{item.uqc}</td>
                      <td className="py-2.5 px-3 text-center font-mono">{item.qty}</td>
                      <td className="py-2.5 px-3 text-right font-mono">{formatRupees(item.totalValPaise)}</td>
                      <td className="py-2.5 px-3 text-center font-bold text-slate-700">{item.rate}%</td>
                      <td className="py-2.5 px-3 text-right font-mono font-bold text-emerald-700">
                        {formatRupees(item.taxPaise)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
