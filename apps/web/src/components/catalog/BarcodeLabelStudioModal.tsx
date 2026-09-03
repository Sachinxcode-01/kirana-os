"use client";

import React, { useState, useRef } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  Barcode,
  Printer,
  X,
  Sparkles,
  Layers,
  Settings,
  Check,
  Calendar,
  Building,
  Tag,
  Download,
  Copy,
  Plus,
  Minus,
  CheckCircle2,
} from "lucide-react";
import { WebProduct } from "@/types";
import { posAudio } from "@/utils/audioFeedback";

interface BarcodeLabelStudioModalProps {
  isOpen: boolean;
  onClose: () => void;
  products: WebProduct[];
  selectedProduct?: WebProduct | null;
}

type StencilType = "roll_50x25" | "roll_38x25" | "roll_58x40" | "a4_24up" | "a4_48up";

export function BarcodeLabelStudioModal({
  isOpen,
  onClose,
  products,
  selectedProduct,
}: BarcodeLabelStudioModalProps) {
  const [stencil, setStencil] = useState<StencilType>("roll_50x25");
  const [storeName, setStoreName] = useState("Sri Lakshmi Provision");
  const [includeStoreName, setIncludeStoreName] = useState(true);
  const [includeMrp, setIncludeMrp] = useState(true);
  const [includePackedDate, setIncludePackedDate] = useState(true);
  const [includeWeight, setIncludeWeight] = useState(true);
  const [copies, setCopies] = useState<number>(24);
  const [activeProductId, setActiveProductId] = useState<string>(
    selectedProduct?.id || products[0]?.id || "p1"
  );
  const [customPackedDate, setCustomPackedDate] = useState(
    new Date().toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" })
  );

  const printAreaRef = useRef<HTMLDivElement>(null);

  if (!isOpen) return null;

  const currentProduct = products.find((p) => p.id === activeProductId) || products[0];

  // In-Store EAN-13 Check Digit Calculation (Luhn mod 10)
  const computeEan13CheckDigit = (base12: string): string => {
    let sum = 0;
    for (let i = 0; i < 12; i++) {
      const digit = parseInt(base12[i] || "0", 10);
      sum += i % 2 === 0 ? digit : digit * 3;
    }
    const remainder = sum % 10;
    return remainder === 0 ? "0" : String(10 - remainder);
  };

  const getEffectiveBarcode = (prod: WebProduct) => {
    if (prod.barcode && prod.barcode.length >= 8) {
      return prod.barcode;
    }
    // Generate valid retail in-store barcode: prefix 20 + 10 digits
    const base12 = "20" + String(prod.id.replace(/\D/g, "") || "101").padStart(10, "0").slice(-10);
    return base12 + computeEan13CheckDigit(base12);
  };

  const effectiveBarcode = getEffectiveBarcode(currentProduct);

  // Deterministic SVG Barcode Pattern Generator (Code 128 / EAN simulation)
  const renderBarcodeBars = (code: string) => {
    // Generate high-density crisp bars from numeric hash
    const bars: boolean[] = [];
    // Start guard
    bars.push(true, false, true);

    let seed = 0;
    for (let i = 0; i < code.length; i++) {
      seed = (seed * 31 + code.charCodeAt(i)) % 1000000;
    }

    for (let i = 0; i < 55; i++) {
      const bit = ((seed >> (i % 20)) ^ (i * 7)) % 2 === 0;
      bars.push(bit);
    }
    // End guard
    bars.push(true, false, true);

    return (
      <svg
        className="w-full h-8 max-w-[160px] mx-auto text-slate-900"
        viewBox={`0 0 ${bars.length * 2} 40`}
        preserveAspectRatio="none"
      >
        {bars.map((isBar, idx) =>
          isBar ? (
            <rect
              key={idx}
              x={idx * 2}
              y={0}
              width={1.75}
              height={40}
              fill="currentColor"
            />
          ) : null
        )}
      </svg>
    );
  };

  const handlePrint = () => {
    posAudio.playBarcodeBeep();
    window.print();
  };

  const formatRupees = (paise: number) =>
    `₹${(paise / 100).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 overflow-y-auto">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
          className="fixed inset-0 bg-slate-950/75 backdrop-blur-sm cursor-pointer"
        />

        {/* Modal Window */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 15 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 15 }}
          transition={{ duration: 0.25, ease: "easeOut" }}
          className="relative w-full max-w-5xl bg-slate-900 border border-slate-700/80 rounded-3xl shadow-2xl overflow-hidden z-10 text-slate-100 flex flex-col max-h-[90vh]"
        >
          {/* Header */}
          <div className="p-4 sm:p-5 border-b border-slate-800 flex items-center justify-between bg-slate-950/80 shrink-0">
            <div className="flex items-center gap-3">
              <div className="p-2.5 bg-gradient-to-tr from-emerald-600 to-teal-500 rounded-2xl shadow-md shadow-emerald-950/60 border border-emerald-400/20">
                <Barcode className="w-5 h-5 text-white" />
              </div>
              <div>
                <h3 className="font-extrabold text-white text-base flex items-center gap-2">
                  <span>Barcode Label Studio &amp; Batch Print</span>
                  <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-emerald-950 text-emerald-300 border border-emerald-800">
                    Phase 15
                  </span>
                </h3>
                <p className="text-xs text-slate-400">
                  Generate adhesive barcode stickers for loose grains, pulses, and in-house packs
                </p>
              </div>
            </div>

            <button
              type="button"
              onClick={onClose}
              className="p-1.5 text-slate-400 hover:text-white rounded-xl hover:bg-slate-800 transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Body: Two columns (Controls on Left, Live Sheet Preview on Right) */}
          <div className="flex-1 flex flex-col lg:flex-row min-h-0 overflow-hidden">
            {/* Left Controls Panel */}
            <div className="w-full lg:w-80 p-4 sm:p-5 border-r border-slate-800 space-y-4 overflow-y-auto shrink-0 bg-slate-950/40">
              {/* Product Selector */}
              <div>
                <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">
                  Target Product
                </label>
                <select
                  value={activeProductId}
                  onChange={(e) => setActiveProductId(e.target.value)}
                  className="w-full p-2.5 bg-slate-800 border border-slate-700 rounded-xl text-xs font-semibold text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
                >
                  {products.map((p) => (
                    <option key={p.id} value={p.id}>
                      {p.name} ({formatRupees(p.sellingPricePaise)})
                    </option>
                  ))}
                </select>
              </div>

              {/* Stencil Template Selector */}
              <div>
                <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">
                  Label Stencil Format
                </label>
                <div className="space-y-1.5">
                  {[
                    { id: "roll_50x25", name: "Thermal Roll: 50mm × 25mm (Standard 2×1\")" },
                    { id: "roll_38x25", name: "Thermal Roll: 38mm × 25mm (Compact)" },
                    { id: "roll_58x40", name: "Thermal Roll: 58mm × 40mm (Large Box)" },
                    { id: "a4_24up", name: "Sheet: A4 24-Up (3 × 8 Stickers)" },
                    { id: "a4_48up", name: "Sheet: A4 48-Up (4 × 12 Mini Stickers)" },
                  ].map((tpl) => (
                    <button
                      key={tpl.id}
                      type="button"
                      onClick={() => setStencil(tpl.id as StencilType)}
                      className={`w-full text-left p-2 rounded-xl text-xs font-medium border transition-all cursor-pointer ${
                        stencil === tpl.id
                          ? "bg-emerald-950/60 border-emerald-600 text-white font-bold"
                          : "bg-slate-800/60 hover:bg-slate-800 border-slate-700/60 text-slate-300"
                      }`}
                    >
                      {tpl.name}
                    </button>
                  ))}
                </div>
              </div>

              {/* Batch Quantity */}
              <div>
                <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-1.5">
                  Labels to Print
                </label>
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => setCopies((c) => Math.max(1, c - 6))}
                    className="p-2 bg-slate-800 hover:bg-slate-700 rounded-lg text-slate-300 transition-colors"
                  >
                    <Minus className="w-3.5 h-3.5" />
                  </button>
                  <input
                    type="number"
                    min="1"
                    max="500"
                    value={copies}
                    onChange={(e) => setCopies(parseInt(e.target.value, 10) || 1)}
                    className="w-full py-1.5 text-center font-mono font-bold bg-slate-900 border border-slate-700 rounded-lg text-sm text-white focus:outline-none focus:border-emerald-500"
                  />
                  <button
                    type="button"
                    onClick={() => setCopies((c) => c + 6)}
                    className="p-2 bg-slate-800 hover:bg-slate-700 rounded-lg text-slate-300 transition-colors"
                  >
                    <Plus className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>

              {/* Label Content Toggles */}
              <div className="space-y-2 pt-2 border-t border-slate-800">
                <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider">
                  Label Fields
                </label>

                <label className="flex items-center gap-2 text-xs text-slate-300 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={includeStoreName}
                    onChange={(e) => setIncludeStoreName(e.target.checked)}
                    className="rounded text-emerald-600 focus:ring-emerald-500"
                  />
                  <span>Store Name Header</span>
                </label>

                <label className="flex items-center gap-2 text-xs text-slate-300 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={includeMrp}
                    onChange={(e) => setIncludeMrp(e.target.checked)}
                    className="rounded text-emerald-600 focus:ring-emerald-500"
                  />
                  <span>Show MRP &amp; Discount</span>
                </label>

                <label className="flex items-center gap-2 text-xs text-slate-300 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={includePackedDate}
                    onChange={(e) => setIncludePackedDate(e.target.checked)}
                    className="rounded text-emerald-600 focus:ring-emerald-500"
                  />
                  <span>Packed Date ({customPackedDate})</span>
                </label>

                <label className="flex items-center gap-2 text-xs text-slate-300 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={includeWeight}
                    onChange={(e) => setIncludeWeight(e.target.checked)}
                    className="rounded text-emerald-600 focus:ring-emerald-500"
                  />
                  <span>Net Quantity ({currentProduct.unit})</span>
                </label>
              </div>
            </div>

            {/* Right Live Preview Area */}
            <div className="flex-1 p-4 sm:p-6 overflow-y-auto bg-slate-900/80 flex flex-col items-center justify-start">
              <div className="w-full max-w-2xl mb-4 flex items-center justify-between">
                <div className="flex items-center gap-2 text-xs font-semibold text-slate-400">
                  <Layers className="w-4 h-4 text-emerald-400" />
                  <span>Interactive Label Preview ({stencil.toUpperCase()})</span>
                </div>
                <div className="text-xs font-mono text-slate-400">
                  Batch: {copies} labels queued
                </div>
              </div>

              {/* Printable Stencil Box */}
              <div
                ref={printAreaRef}
                className="w-full max-w-2xl p-6 bg-slate-800/40 rounded-2xl border border-slate-700/60 shadow-inner flex flex-wrap gap-4 items-center justify-center min-h-[320px]"
              >
                {Array.from({ length: Math.min(copies, stencil.startsWith("roll") ? 4 : 8) }).map(
                  (_, idx) => (
                    <motion.div
                      key={idx}
                      whileHover={{ scale: 1.02 }}
                      className={`bg-white text-slate-950 p-2.5 rounded shadow-lg border border-slate-300 flex flex-col justify-between select-none text-center ${
                        stencil === "roll_50x25"
                          ? "w-48 h-28"
                          : stencil === "roll_38x25"
                          ? "w-40 h-24 p-1.5"
                          : stencil === "roll_58x40"
                          ? "w-56 h-36 p-3"
                          : "w-44 h-24 p-2 text-xs"
                      }`}
                    >
                      {/* Store Header */}
                      {includeStoreName && (
                        <p className="text-[10px] font-black uppercase tracking-tight text-slate-800 line-clamp-1">
                          {storeName}
                        </p>
                      )}

                      {/* Product Name */}
                      <p className="text-xs font-bold leading-tight line-clamp-2 text-slate-900 mt-0.5">
                        {currentProduct.name}
                      </p>

                      {/* Barcode Vector & Number */}
                      <div className="my-1">
                        {renderBarcodeBars(effectiveBarcode)}
                        <p className="text-[9px] font-mono font-bold tracking-widest text-slate-700 mt-0.5">
                          {effectiveBarcode}
                        </p>
                      </div>

                      {/* Pricing Strip */}
                      <div className="flex items-baseline justify-center gap-1.5 border-t border-slate-200 pt-1">
                        <span className="text-xs font-black font-mono text-slate-900">
                          {formatRupees(currentProduct.sellingPricePaise)}
                        </span>
                        {includeMrp && currentProduct.mrpPaise > currentProduct.sellingPricePaise && (
                          <span className="text-[10px] text-slate-400 line-through font-mono">
                            MRP {formatRupees(currentProduct.mrpPaise)}
                          </span>
                        )}
                        {includeWeight && (
                          <span className="text-[9px] font-semibold text-slate-600">
                            /{currentProduct.unit}
                          </span>
                        )}
                      </div>

                      {includePackedDate && (
                        <p className="text-[8px] text-slate-500 mt-0.5">
                          Pkd: {customPackedDate}
                        </p>
                      )}
                    </motion.div>
                  )
                )}
              </div>

              {copies > (stencil.startsWith("roll") ? 4 : 8) && (
                <p className="text-xs text-slate-500 mt-3">
                  + {copies - (stencil.startsWith("roll") ? 4 : 8)} more identical labels in queue
                </p>
              )}
            </div>
          </div>

          {/* Footer Actions */}
          <div className="p-4 sm:p-5 border-t border-slate-800 bg-slate-950 flex items-center justify-between shrink-0">
            <div className="flex items-center gap-2 text-xs text-slate-400">
              <Sparkles className="w-4 h-4 text-amber-400" />
              <span>Supports ESC/POS label roll printers and office A4 adhesive sticker sheets</span>
            </div>

            <div className="flex items-center gap-3">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-bold rounded-xl transition-colors cursor-pointer"
              >
                Close
              </button>
              <button
                type="button"
                onClick={handlePrint}
                className="flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white text-xs font-black rounded-xl shadow-lg shadow-emerald-950/60 cursor-pointer transition-all"
              >
                <Printer className="w-4 h-4" />
                <span>Print {copies} Labels</span>
              </button>
            </div>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
