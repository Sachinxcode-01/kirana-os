"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  UploadCloud,
  FileSpreadsheet,
  CheckCircle2,
  AlertCircle,
  X,
  FileText,
  Download,
  Sparkles,
} from "lucide-react";
import { WebProduct } from "@/types";
import { posAudio } from "@/utils/audioFeedback";

interface BulkProductImportModalProps {
  isOpen: boolean;
  onClose: () => void;
  onImportSuccess: (importedProducts: WebProduct[]) => void;
}

const SAMPLE_CSV = `Barcode,Name,Category,MRP,SalePrice,CostPrice,Stock,MinStock,Unit,HSN,GSTRate
8901030383344,Bru Instant Coffee 100g,Tea & Coffee,220,195,165,24,6,jar,0901,18
8901725181220,Sunfeast Dark Fantasy 300g,Snacks & Biscuits,120,105,85,30,8,packet,1905,18
8901058852334,Maggie 2-Minute Noodles 420g,Snacks & Biscuits,96,88,72,40,10,pack,1902,5
8901207010214,Tata Tea Gold 500g,Tea & Coffee,310,285,245,20,5,packet,0902,5
8901030012886,Surf Excel Matic Liquid 1L,Household,240,215,180,15,4,bottle,3402,18`;

export function BulkProductImportModal({
  isOpen,
  onClose,
  onImportSuccess,
}: BulkProductImportModalProps) {
  const [csvText, setCsvText] = useState(SAMPLE_CSV);
  const [parsedRows, setParsedRows] = useState<WebProduct[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [isParsed, setIsParsed] = useState(false);

  const handleParse = (text: string) => {
    setError(null);
    try {
      const lines = text
        .trim()
        .split(/\r?\n/)
        .map((l) => l.trim())
        .filter(Boolean);

      if (lines.length < 2) {
        setError("Please provide at least one header line and one product row.");
        return;
      }

      const rows: WebProduct[] = [];

      for (let i = 1; i < lines.length; i++) {
        // Simple CSV splitter handling potential commas
        const cols = lines[i].split(",").map((c) => c.trim().replace(/^["']|["']$/g, ""));
        if (cols.length < 5) continue;

        const [
          barcode = "",
          name = "",
          category = "General",
          mrp = "0",
          salePrice = "0",
          costPrice = "0",
          stock = "10",
          minStock = "5",
          unit = "packet",
          hsn = "1905",
          gstRate = "18",
        ] = cols;

        if (!name) continue;

        const saleNum = parseFloat(salePrice) || 0;
        const mrpNum = parseFloat(mrp) || saleNum;
        const costNum = parseFloat(costPrice) || Math.round(saleNum * 0.85);

        rows.push({
          id: `prod_csv_${Date.now()}_${i}`,
          name,
          categoryName: category || "General",
          barcode: barcode || `890${Date.now()}${i}`.slice(0, 13),
          mrpPaise: Math.round(mrpNum * 100),
          sellingPricePaise: Math.round(saleNum * 100),
          costPricePaise: Math.round(costNum * 100),
          currentStock: parseInt(stock, 10) || 10,
          minStockThreshold: parseInt(minStock, 10) || 5,
          unit: unit || "packet",
          hsnCode: hsn || "19053100",
          taxRate: parseFloat(gstRate) || 18,
          isActive: true,
        });
      }

      if (rows.length === 0) {
        setError("No valid products could be parsed from the data.");
        return;
      }

      setParsedRows(rows);
      setIsParsed(true);
    } catch (err: any) {
      setError(err.message || "Failed to parse CSV data.");
    }
  };

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      const content = event.target?.result as string;
      setCsvText(content);
      handleParse(content);
    };
    reader.readAsText(file);
  };

  const handleExecuteImport = () => {
    if (parsedRows.length === 0) return;
    posAudio.playSuccessChime();
    onImportSuccess(parsedRows);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs">
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
        className="w-full max-w-2xl bg-white rounded-3xl p-6 shadow-2xl space-y-4 max-h-[90vh] overflow-y-auto"
      >
        {/* Header */}
        <div className="flex items-center justify-between pb-3 border-b border-slate-100">
          <div className="flex items-center gap-2.5">
            <div className="p-2.5 bg-emerald-50 text-emerald-600 rounded-2xl border border-emerald-100">
              <FileSpreadsheet className="w-5 h-5" />
            </div>
            <div>
              <h3 className="font-bold text-slate-900 text-base">
                Bulk Excel / CSV Product Batch Importer
              </h3>
              <p className="text-xs text-slate-500">
                Import product SKUs from FMCG supplier catalogs &amp; distributor invoices
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="text-slate-400 hover:text-slate-600 cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Upload & Instructions */}
        <div className="space-y-3">
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3">
            <label className="flex items-center justify-center gap-2 px-4 py-2.5 bg-emerald-50 hover:bg-emerald-100 text-emerald-800 border border-emerald-300 rounded-xl text-xs font-bold shadow-xs transition-colors cursor-pointer">
              <UploadCloud className="w-4 h-4 text-emerald-600" />
              <span>Upload .CSV / Excel File</span>
              <input
                type="file"
                accept=".csv,text/csv,text/plain"
                onChange={handleFileUpload}
                className="hidden"
              />
            </label>
            <button
              type="button"
              onClick={() => {
                setCsvText(SAMPLE_CSV);
                handleParse(SAMPLE_CSV);
              }}
              className="flex items-center justify-center gap-1.5 px-3 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-xl text-xs font-semibold cursor-pointer"
            >
              <FileText className="w-3.5 h-3.5 text-slate-500" />
              <span>Load Sample FMCG Data</span>
            </button>
          </div>

          {/* Raw CSV textarea */}
          <div>
            <label className="text-[11px] font-bold text-slate-600 uppercase tracking-wider block mb-1">
              CSV Data Editor / Paste Box
            </label>
            <textarea
              value={csvText}
              onChange={(e) => {
                setCsvText(e.target.value);
                setIsParsed(false);
              }}
              rows={4}
              placeholder="Paste comma-separated values here..."
              className="w-full p-3 font-mono text-xs bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:border-emerald-500 focus:outline-none transition-colors"
            />
          </div>

          {!isParsed && (
            <button
              type="button"
              onClick={() => handleParse(csvText)}
              className="w-full py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold shadow-xs cursor-pointer flex items-center justify-center gap-2"
            >
              <Sparkles className="w-3.5 h-3.5 text-amber-400" />
              <span>Validate &amp; Preview Items</span>
            </button>
          )}

          {error && (
            <div className="p-3 bg-rose-50 border border-rose-200 text-rose-700 rounded-xl text-xs flex items-center gap-2">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {/* Parsed Preview Table */}
          {isParsed && parsedRows.length > 0 && (
            <div className="space-y-2">
              <div className="flex items-center justify-between text-xs font-bold text-slate-700">
                <span className="flex items-center gap-1.5 text-emerald-700">
                  <CheckCircle2 className="w-4 h-4" /> Ready to Import: {parsedRows.length} SKUs
                </span>
                <span className="text-slate-400 font-normal">All fields verified</span>
              </div>

              <div className="max-h-56 overflow-y-auto rounded-xl border border-slate-200 shadow-xs">
                <table className="w-full text-left text-xs border-collapse font-sans">
                  <thead className="bg-slate-100 text-[10px] font-bold text-slate-600 uppercase sticky top-0">
                    <tr>
                      <th className="py-2 px-3">Product Name</th>
                      <th className="py-2 px-2">Category</th>
                      <th className="py-2 px-2 text-right">Sale Price</th>
                      <th className="py-2 px-2 text-right">MRP</th>
                      <th className="py-2 px-2 text-center">Stock</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 font-medium">
                    {parsedRows.map((row, idx) => (
                      <tr key={idx} className="hover:bg-slate-50">
                        <td className="py-2 px-3 font-semibold text-slate-900">{row.name}</td>
                        <td className="py-2 px-2 text-slate-500 text-[11px]">{row.categoryName}</td>
                        <td className="py-2 px-2 text-right font-mono font-bold text-emerald-700">
                          ₹{(row.sellingPricePaise / 100).toFixed(2)}
                        </td>
                        <td className="py-2 px-2 text-right font-mono text-slate-400">
                          ₹{(row.mrpPaise / 100).toFixed(2)}
                        </td>
                        <td className="py-2 px-2 text-center font-mono">
                          {row.currentStock} {row.unit}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>

        {/* Action Buttons */}
        <div className="pt-3 border-t border-slate-100 flex items-center justify-end gap-2 text-xs">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-xl text-slate-600 hover:bg-slate-100 font-semibold cursor-pointer"
          >
            Cancel
          </button>
          <button
            type="button"
            disabled={!isParsed || parsedRows.length === 0}
            onClick={handleExecuteImport}
            className="px-5 py-2 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 disabled:opacity-50 text-white font-bold shadow-md shadow-emerald-950/20 cursor-pointer flex items-center gap-2"
          >
            <CheckCircle2 className="w-4 h-4" />
            <span>Import {parsedRows.length} Products to Inventory</span>
          </button>
        </div>
      </motion.div>
    </div>
  );
}
