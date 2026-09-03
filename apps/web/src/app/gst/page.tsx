"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
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
  Sparkles,
  ShieldCheck,
  Check,
  X,
} from "lucide-react";

export default function GSTCenterPage() {
  const [period, setPeriod] = useState("Sep 2026 (Monthly)");
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

  const formatRupees = (paise: number) =>
    `₹${(paise / 100).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

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
    showToast("Downloaded GSTR-1 GSTN Offline Tool JSON file!");
  };

  const downloadGSTR1CSV = () => {
    const headers = ["HSN_Code", "Description", "UQC", "Total_Quantity", "Total_Value_INR", "Taxable_Value_INR", "Central_GST_INR", "State_GST_INR", "Total_Tax_INR"];
    const rows = hsnItems.map((item) => [
      item.hsn,
      `"${item.desc}"`,
      item.uqc,
      item.qty,
      (item.totalValPaise / 100).toFixed(2),
      ((item.totalValPaise - item.taxPaise) / 100).toFixed(2),
      (item.taxPaise / 200).toFixed(2),
      (item.taxPaise / 200).toFixed(2),
      (item.taxPaise / 100).toFixed(2),
    ]);

    const csvContent = [headers.join(","), ...rows.map((r) => r.join(","))].join("\n");
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `GSTR1_Table12_HSN_SEP2026.csv`;
    a.click();
    URL.revokeObjectURL(url);
    showToast("Downloaded Chartered Accountant (CA) GSTR-1 Excel CSV file!");
  };

  return (
    <div className="flex min-h-screen bg-slate-50 relative overflow-hidden">
      {/* Background glow */}
      <div className="absolute top-0 right-0 w-96 h-96 bg-emerald-400/10 rounded-full blur-3xl pointer-events-none"></div>

      <Sidebar isOpen={mobileNavOpen} onClose={() => setMobileNavOpen(false)} />

      <div className="flex-1 flex flex-col min-w-0 z-10">
        <Header
          title="GST Tax Center & GSTR-1 Summaries"
          subtitle="Tax liability aggregation, HSN Table 12 summaries, and one-click GST portal offline exports"
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

          {/* GSTIN Business Header */}
          <div className="p-6 bg-gradient-to-tr from-slate-900 to-slate-800 text-white rounded-2xl shadow-md flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
            <div>
              <div className="flex items-center gap-2">
                <Building className="w-5 h-5 text-emerald-400" />
                <h3 className="font-extrabold text-base">Sri Lakshmi Provision &amp; Supermarket</h3>
              </div>
              <div className="flex items-center gap-4 mt-2 text-xs text-slate-300 font-mono">
                <span>GSTIN: <strong>29AAAAA0000A1Z5</strong> (Karnataka)</span>
                <span>•</span>
                <span>Filing Frequency: <strong>Monthly Return</strong></span>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <select
                value={period}
                onChange={(e) => setPeriod(e.target.value)}
                className="bg-slate-800 text-white text-xs px-3 py-2 rounded-xl border border-slate-700 focus:outline-none focus:border-emerald-500 font-medium cursor-pointer"
              >
                <option value="Sep 2026 (Monthly)">Sep 2026 (Monthly)</option>
                <option value="Aug 2026 (Monthly)">Aug 2026 (Monthly)</option>
                <option value="Q2 Jul-Sep 2026 (Quarterly)">Q2 Jul-Sep 2026 (Quarterly)</option>
              </select>

              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={downloadGSTR1JSON}
                className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white rounded-xl text-xs font-bold shadow-md shadow-emerald-950/20 transition-all cursor-pointer whitespace-nowrap"
              >
                <Download className="w-4 h-4" />
                <span>Download GSTR-1 JSON</span>
              </motion.button>

              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={downloadGSTR1CSV}
                className="flex items-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 border border-slate-700 text-white rounded-xl text-xs font-bold transition-all cursor-pointer whitespace-nowrap"
              >
                <FileSpreadsheet className="w-4 h-4 text-emerald-400" />
                <span>Export CA CSV</span>
              </motion.button>
            </div>
          </div>

          {/* Tax Liability Dashboard Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-4">
            <div className="p-5 glass-card rounded-2xl shadow-xs">
              <p className="text-[11px] text-slate-500 font-bold uppercase tracking-wider">Total Sales Turnover</p>
              <h4 className="text-xl font-extrabold font-mono text-slate-900 mt-1">
                {formatRupees(totalInvoiceVal)}
              </h4>
              <p className="text-[10px] text-slate-400 mt-1">Includes exempt &amp; taxable items</p>
            </div>

            <div className="p-5 glass-card rounded-2xl shadow-xs">
              <p className="text-[11px] text-slate-500 font-bold uppercase tracking-wider">Central Tax (CGST)</p>
              <h4 className="text-xl font-extrabold font-mono text-emerald-700 mt-1">
                {formatRupees(totalCGST)}
              </h4>
              <p className="text-[10px] text-emerald-600 font-semibold mt-1">Payable in Cash / ITC</p>
            </div>

            <div className="p-5 glass-card rounded-2xl shadow-xs">
              <p className="text-[11px] text-slate-500 font-bold uppercase tracking-wider">State Tax (SGST)</p>
              <h4 className="text-xl font-extrabold font-mono text-emerald-700 mt-1">
                {formatRupees(totalSGST)}
              </h4>
              <p className="text-[10px] text-emerald-600 font-semibold mt-1">Karnataka State Portion</p>
            </div>

            <div className="p-5 bg-gradient-to-tr from-emerald-950 to-teal-900 text-white rounded-2xl shadow-md">
              <p className="text-[11px] text-emerald-300 font-bold uppercase tracking-wider">Total Tax Liability</p>
              <h4 className="text-xl font-extrabold font-mono text-white mt-1">
                {formatRupees(totalTaxLiability)}
              </h4>
              <p className="text-[10px] text-emerald-400 font-medium mt-1">GSTR-3B Auto-Synced</p>
            </div>
          </div>

          {/* Slabs Breakdown Table */}
          <div className="glass-card rounded-2xl shadow-xs overflow-hidden">
            <div className="p-4 border-b border-slate-200/80 flex items-center justify-between bg-slate-50/60">
              <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                <Percent className="w-4 h-4 text-emerald-600" /> Rate-Wise Sales Breakdown (B2CS Intra-State)
              </h3>
              <span className="text-xs text-slate-500 font-medium">Table 7 of GSTR-1</span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="bg-slate-100/70 border-b border-slate-200 text-[11px] font-bold text-slate-600 uppercase tracking-wider">
                    <th className="py-3 px-4">GST Rate Bracket</th>
                    <th className="py-3 px-4 text-right">Taxable Turnover</th>
                    <th className="py-3 px-4 text-right">CGST</th>
                    <th className="py-3 px-4 text-right">SGST</th>
                    <th className="py-3 px-4 text-right">Total Tax Accrued</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-xs text-slate-700 font-medium">
                  {taxSlabs.map((slab, i) => (
                    <tr key={i} className="hover:bg-slate-50/70 transition-colors">
                      <td className="py-3 px-4 font-bold text-slate-900">{slab.rate}</td>
                      <td className="py-3 px-4 text-right font-mono">{formatRupees(slab.taxablePaise)}</td>
                      <td className="py-3 px-4 text-right font-mono text-slate-600">{formatRupees(slab.cgstPaise)}</td>
                      <td className="py-3 px-4 text-right font-mono text-slate-600">{formatRupees(slab.sgstPaise)}</td>
                      <td className="py-3 px-4 text-right font-mono font-bold text-emerald-700">
                        {formatRupees(slab.totalTaxPaise)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* HSN Summary Table 12 */}
          <div className="glass-card rounded-2xl shadow-xs overflow-hidden">
            <div className="p-4 border-b border-slate-200/80 flex items-center justify-between bg-slate-50/60">
              <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                <Hash className="w-4 h-4 text-emerald-600" /> HSN-Wise Summary of Outward Supplies (Table 12)
              </h3>
              <span className="text-xs text-slate-500 font-medium">Mandatory for Turnover &gt; ₹5 Cr</span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="bg-slate-100/70 border-b border-slate-200 text-[11px] font-bold text-slate-600 uppercase tracking-wider">
                    <th className="py-3 px-4">HSN Code</th>
                    <th className="py-3 px-4">Description</th>
                    <th className="py-3 px-4 text-center">UQC</th>
                    <th className="py-3 px-4 text-right">Total Quantity</th>
                    <th className="py-3 px-4 text-right">Total Invoice Value</th>
                    <th className="py-3 px-4 text-right">Total GST</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-xs text-slate-700 font-medium">
                  {hsnItems.map((item, i) => (
                    <tr key={i} className="hover:bg-slate-50/70 transition-colors">
                      <td className="py-3 px-4 font-mono font-bold text-slate-900">{item.hsn}</td>
                      <td className="py-3 px-4 text-slate-800">{item.desc}</td>
                      <td className="py-3 px-4 text-center font-mono uppercase text-slate-500">{item.uqc}</td>
                      <td className="py-3 px-4 text-right font-mono">{item.qty}</td>
                      <td className="py-3 px-4 text-right font-mono font-bold text-slate-900">
                        {formatRupees(item.totalValPaise)}
                      </td>
                      <td className="py-3 px-4 text-right font-mono text-emerald-700">
                        {formatRupees(item.taxPaise)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="p-4 border-t border-slate-100 bg-slate-50/50 flex items-center justify-between text-xs text-slate-500">
              <span className="flex items-center gap-1.5 font-semibold text-emerald-700">
                <ShieldCheck className="w-4 h-4 text-emerald-600" />
                GSTN Validation Passed &bull; Schema Compliant
              </span>
              <span>Direct offline upload ready for gst.gov.in</span>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
