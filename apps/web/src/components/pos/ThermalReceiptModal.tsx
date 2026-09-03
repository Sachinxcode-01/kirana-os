"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  Printer,
  X,
  QrCode,
  Download,
  CheckCircle2,
  Copy,
  Store,
  Share2,
} from "lucide-react";
import { posAudio } from "@/utils/audioFeedback";

export interface ReceiptItem {
  name: string;
  qty: number;
  ratePaise: number;
  totalPaise: number;
  hsn?: string;
}

interface ThermalReceiptModalProps {
  isOpen: boolean;
  onClose: () => void;
  invoiceData?: {
    invoiceNumber?: string;
    dateStr?: string;
    cashierName?: string;
    customerName?: string;
    paymentMode?: string;
    items?: ReceiptItem[];
    subtotalPaise?: number;
    gstPaise?: number;
    totalPaise?: number;
  };
}

export function ThermalReceiptModal({
  isOpen,
  onClose,
  invoiceData,
}: ThermalReceiptModalProps) {
  const [paperWidth, setPaperWidth] = useState<"58mm" | "80mm">("80mm");
  const [isCopied, setIsCopied] = useState(false);

  if (!isOpen) return null;

  const defaultItems: ReceiptItem[] = [
    { name: "Aashirvaad Shudh Atta 5kg", qty: 1, ratePaise: 24500, totalPaise: 24500, hsn: "1101" },
    { name: "Fortune Sunlite Oil 1L", qty: 2, ratePaise: 13500, totalPaise: 27000, hsn: "1512" },
    { name: "Tata Salt Vacuum Evap 1kg", qty: 1, ratePaise: 2800, totalPaise: 2800, hsn: "2501" },
    { name: "Maggi 2-Min Masala Noodles 70g", qty: 4, ratePaise: 1400, totalPaise: 5600, hsn: "1902" },
  ];

  const items = invoiceData?.items || defaultItems;
  const subtotalPaise =
    invoiceData?.subtotalPaise || items.reduce((acc, it) => acc + it.totalPaise, 0);
  const gstPaise = invoiceData?.gstPaise || Math.round(subtotalPaise * 0.05);
  const totalPaise = invoiceData?.totalPaise || subtotalPaise + gstPaise;

  const invoiceNumber = invoiceData?.invoiceNumber || "INV-2026-0043";
  const dateStr =
    invoiceData?.dateStr ||
    new Date().toLocaleDateString("en-IN", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      hour12: true,
    });
  const cashierName = invoiceData?.cashierName || "Ramesh Kumar (POS-01)";
  const paymentMode = invoiceData?.paymentMode || "Cash Tender";

  const handlePrint = () => {
    posAudio.playSuccessChime();
    window.print();
  };

  const handleCopyBill = () => {
    const text = `Sri Lakshmi Provision - Bill ${invoiceNumber}\nDate: ${dateStr}\nTotal: ₹${(
      totalPaise / 100
    ).toFixed(2)}\nThank you for shopping with us!`;
    navigator.clipboard.writeText(text);
    setIsCopied(true);
    posAudio.playBarcodeBeep();
    setTimeout(() => setIsCopied(false), 2000);
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
          className="absolute inset-0 bg-slate-950/75 backdrop-blur-sm cursor-pointer"
        />

        {/* Modal Surface */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 15 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 15 }}
          transition={{ duration: 0.25, ease: "easeOut" }}
          className="relative w-full max-w-xl bg-slate-900 border border-slate-700/80 rounded-3xl shadow-2xl overflow-hidden z-10 text-slate-100 flex flex-col max-h-[90vh]"
        >
          {/* Header Controls */}
          <div className="flex items-center justify-between p-4 border-b border-slate-800 bg-slate-900/90 z-20">
            <div className="flex items-center gap-2.5">
              <div className="p-2 bg-gradient-to-br from-emerald-600 to-teal-600 rounded-xl text-white shadow-xs">
                <Printer className="w-4 h-4" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-white flex items-center gap-1.5">
                  <span>ESC/POS Thermal Receipt</span>
                  <kbd className="px-1.5 py-0.2 rounded text-[10px] font-mono font-bold bg-slate-800 text-emerald-300 border border-slate-700">
                    F8
                  </kbd>
                </h3>
                <p className="text-[11px] text-slate-400">Direct print preview formatted for POS roll paper</p>
              </div>
            </div>

            <div className="flex items-center gap-2">
              {/* Width Selector */}
              <div className="flex items-center gap-1 p-0.5 bg-slate-950 rounded-xl border border-slate-800 text-[11px] font-bold">
                <button
                  type="button"
                  onClick={() => setPaperWidth("58mm")}
                  className={`px-2 py-1 rounded-lg transition-all cursor-pointer ${
                    paperWidth === "58mm"
                      ? "bg-slate-800 text-emerald-400 shadow-xs"
                      : "text-slate-400 hover:text-white"
                  }`}
                >
                  58mm Roll
                </button>
                <button
                  type="button"
                  onClick={() => setPaperWidth("80mm")}
                  className={`px-2 py-1 rounded-lg transition-all cursor-pointer ${
                    paperWidth === "80mm"
                      ? "bg-slate-800 text-emerald-400 shadow-xs"
                      : "text-slate-400 hover:text-white"
                  }`}
                >
                  80mm Roll
                </button>
              </div>

              <button
                onClick={onClose}
                className="p-1.5 text-slate-400 hover:text-white rounded-xl hover:bg-slate-800 transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
          </div>

          {/* Scrollable Receipt Body */}
          <div className="p-6 overflow-y-auto flex items-center justify-center bg-slate-950/60">
            {/* The Physical Paper Slip */}
            <div
              id="thermal-receipt-printable"
              className={`bg-white text-slate-900 font-mono p-5 rounded-t-lg shadow-2xl transition-all duration-300 relative border-x border-t border-slate-200 ${
                paperWidth === "58mm" ? "w-[300px] text-[10px]" : "w-[380px] text-[11px]"
              }`}
              style={{
                filter: "drop-shadow(0 10px 25px rgba(0,0,0,0.5))",
              }}
            >
              {/* Store Brand Header */}
              <div className="text-center space-y-1 pb-3 border-b-2 border-dashed border-slate-300">
                <h2 className="font-black text-sm uppercase tracking-wide">
                  Sri Lakshmi Provision Store
                </h2>
                <p className="text-[10px] text-slate-600 leading-tight">
                  #142, 8th Main, 4th Cross, Indiranagar, Bengaluru - 560038
                </p>
                <p className="text-[10px] text-slate-600 font-bold">
                  GSTIN: 29AAAAA0000A1Z5 &bull; Ph: 9845012345
                </p>
              </div>

              {/* Invoice Meta */}
              <div className="py-2.5 space-y-0.5 border-b border-dashed border-slate-300 text-[10px]">
                <div className="flex justify-between">
                  <span className="text-slate-500">Invoice No:</span>
                  <span className="font-bold">{invoiceNumber}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Date &amp; Time:</span>
                  <span>{dateStr}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Cashier:</span>
                  <span>{cashierName}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Tender Mode:</span>
                  <span className="font-bold uppercase">{paymentMode}</span>
                </div>
              </div>

              {/* Items Table */}
              <div className="py-3 border-b-2 border-dashed border-slate-300 space-y-1.5">
                <div className="flex justify-between font-bold uppercase pb-1 border-b border-slate-200 text-[10px]">
                  <span>Item</span>
                  <div className="flex gap-4">
                    <span>Qty</span>
                    <span>Amt</span>
                  </div>
                </div>

                {items.map((it, idx) => (
                  <div key={idx} className="space-y-0.5 leading-snug">
                    <div className="flex justify-between">
                      <span className="font-semibold truncate max-w-[180px]">{it.name}</span>
                      <span className="font-bold shrink-0">
                        ₹{(it.totalPaise / 100).toFixed(2)}
                      </span>
                    </div>
                    <div className="flex justify-between text-[9px] text-slate-500">
                      <span>HSN: {it.hsn || "1905"}</span>
                      <span>
                        {it.qty} x ₹{(it.ratePaise / 100).toFixed(2)}
                      </span>
                    </div>
                  </div>
                ))}
              </div>

              {/* Totals & Tax Breakdown */}
              <div className="py-2.5 space-y-1 border-b-2 border-dashed border-slate-300">
                <div className="flex justify-between text-slate-600">
                  <span>Subtotal:</span>
                  <span>₹{(subtotalPaise / 100).toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span>CGST (2.5%):</span>
                  <span>₹{((gstPaise / 2) / 100).toFixed(2)}</span>
                </div>
                <div className="flex justify-between text-slate-600">
                  <span>SGST (2.5%):</span>
                  <span>₹{((gstPaise / 2) / 100).toFixed(2)}</span>
                </div>
                <div className="flex justify-between font-black text-sm pt-1 border-t border-slate-300">
                  <span>NET TOTAL:</span>
                  <span>₹{(totalPaise / 100).toFixed(2)}</span>
                </div>
              </div>

              {/* Dynamic Bharat UPI QR Code */}
              <div className="py-4 text-center space-y-2">
                <div className="inline-block p-2 bg-slate-50 border border-slate-300 rounded-xl">
                  {/* Authentic SVG QR Code placeholder */}
                  <svg className="w-24 h-24 mx-auto text-slate-900" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M2 2h8v8H2V2zm2 2v4h4V4H4zm10-2h8v8h-8V2zm2 2v4h4V4h-4zM2 14h8v8H2v-8zm2 2v4h4v-4H4zm14 0h4v4h-4v-4zm-4 0h2v2h-2v-2zm0 4h2v2h-2v-2zm4-4h2v2h-2v-2zm-6-6h2v2h-2v-2zm4 0h2v2h-2v-2zm-2 2h2v2h-2v-2zm6 0h2v2h-2v-2z" />
                  </svg>
                </div>
                <p className="text-[9px] text-slate-500 font-bold uppercase tracking-wider">
                  Scan to Pay via PhonePe / GPay / Paytm
                </p>
                <p className="text-[10px] font-bold text-slate-700">
                  UPI ID: srilakshmi.kirana@okhdfcbank
                </p>
              </div>

              {/* Footer Goodwill Message */}
              <div className="text-center pt-2 pb-1 border-t border-dashed border-slate-300 space-y-0.5 text-[9px] text-slate-500">
                <p className="font-bold text-slate-800 uppercase tracking-widest">
                  ** THANK YOU VISIT AGAIN **
                </p>
                <p>Goods once sold can be exchanged within 48 hours.</p>
                <p>Generated via KiranaOS Retail ERP</p>
              </div>

              {/* Serrated Bottom Paper Edge */}
              <div
                className="absolute bottom-0 left-0 right-0 h-2 bg-slate-900 -mb-2"
                style={{
                  clipPath:
                    "polygon(0% 0%, 5% 100%, 10% 0%, 15% 100%, 20% 0%, 25% 100%, 30% 0%, 35% 100%, 40% 0%, 45% 100%, 50% 0%, 55% 100%, 60% 0%, 65% 100%, 70% 0%, 75% 100%, 80% 0%, 85% 100%, 90% 0%, 95% 100%, 100% 0%)",
                }}
              />
            </div>
          </div>

          {/* Modal Footer Controls */}
          <div className="p-4 border-t border-slate-800 bg-slate-900 flex items-center justify-between gap-3">
            <button
              type="button"
              onClick={handleCopyBill}
              className="px-3 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 cursor-pointer"
            >
              {isCopied ? <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
              <span>{isCopied ? "Copied Bill Text" : "Copy Receipt Text"}</span>
            </button>

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-bold transition-all cursor-pointer"
              >
                Close (Esc)
              </button>

              <button
                type="button"
                onClick={handlePrint}
                className="px-5 py-2 bg-gradient-to-r from-emerald-600 via-teal-600 to-emerald-500 hover:from-emerald-500 hover:to-teal-500 text-white rounded-xl text-xs font-black shadow-lg shadow-emerald-950/60 flex items-center gap-2 cursor-pointer transition-all"
              >
                <Printer className="w-4 h-4" />
                <span>Direct Print (F8)</span>
              </button>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Print Isolated CSS */}
      <style jsx global>{`
        @media print {
          body * {
            visibility: hidden;
          }
          #thermal-receipt-printable,
          #thermal-receipt-printable * {
            visibility: visible;
          }
          #thermal-receipt-printable {
            position: absolute;
            left: 0;
            top: 0;
            width: 100% !important;
            box-shadow: none !important;
            border: none !important;
          }
        }
      `}</style>
    </AnimatePresence>
  );
}
