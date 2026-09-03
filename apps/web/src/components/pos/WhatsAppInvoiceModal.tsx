"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { MessageSquare, X, Send, QrCode, Check, Copy } from "lucide-react";
import { posAudio } from "@/utils/audioFeedback";

interface WhatsAppInvoiceModalProps {
  isOpen: boolean;
  onClose: () => void;
  invoice: {
    invoiceNumber: string;
    customerName: string;
    dateStr: string;
    totalPaise: number;
    paymentMode: string;
  } | null;
}

export function WhatsAppInvoiceModal({ isOpen, onClose, invoice }: WhatsAppInvoiceModalProps) {
  const [phoneNumber, setPhoneNumber] = useState("9845012345");
  const [isCopied, setIsCopied] = useState(false);

  if (!isOpen || !invoice) return null;

  const totalRupees = (invoice.totalPaise / 100).toFixed(2);
  const upiPayLink = `upi://pay?pa=srilakshmi.kirana@okhdfcbank&pn=SriLakshmiProvision&am=${totalRupees}&cu=INR&tn=${invoice.invoiceNumber}`;

  const messageText = `🧾 *SRI LAKSHMI PROVISION STORE*
Indiranagar, Bengaluru - 560038
GSTIN: 29AAAAA0000A1Z5 | Ph: 9845012345
-----------------------------------
*Digital Cash Memo*
Invoice: *${invoice.invoiceNumber}*
Customer: *${invoice.customerName}*
Date: ${invoice.dateStr}
Payment: *${invoice.paymentMode.toUpperCase()}*
-----------------------------------
*NET AMOUNT: ₹${totalRupees}*
-----------------------------------
📲 *Click to Pay via UPI (GPay / PhonePe / Paytm):*
${upiPayLink}
-----------------------------------
Thank you for shopping with us!
_Powered by KiranaOS Retail ERP_`;

  const handleSendWhatsApp = () => {
    posAudio.playSuccessChime();
    const cleanPhone = phoneNumber.replace(/[^0-9]/g, "");
    const fullNumber = cleanPhone.length === 10 ? `91${cleanPhone}` : cleanPhone;
    const url = `https://wa.me/${fullNumber}?text=${encodeURIComponent(messageText)}`;
    window.open(url, "_blank");
    onClose();
  };

  const handleCopyText = async () => {
    await navigator.clipboard.writeText(messageText);
    posAudio.playBarcodeBeep();
    setIsCopied(true);
    setTimeout(() => setIsCopied(false), 2000);
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
          className="absolute inset-0 bg-slate-950/70 backdrop-blur-sm cursor-pointer"
        />

        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 10 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 10 }}
          className="relative w-full max-w-lg bg-white rounded-3xl shadow-2xl border border-slate-200 overflow-hidden z-10"
        >
          {/* Header */}
          <div className="flex items-center justify-between p-5 border-b border-slate-100 bg-[#25D366]/10">
            <div className="flex items-center gap-3">
              <div className="p-2.5 bg-[#25D366] text-white rounded-2xl shadow-md">
                <MessageSquare className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-base font-black text-slate-900">Send WhatsApp Invoice</h3>
                <p className="text-xs text-slate-500">Digital bill &amp; dynamic UPI recovery link</p>
              </div>
            </div>

            <button
              onClick={onClose}
              className="p-1.5 text-slate-400 hover:text-slate-700 rounded-xl hover:bg-white/60 transition-colors cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Form Body */}
          <div className="p-6 space-y-4">
            {/* Phone Number Input */}
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-slate-700">Customer Mobile Number</label>
              <div className="flex items-center border border-slate-200 rounded-xl overflow-hidden focus-within:border-emerald-500 focus-within:ring-2 focus-within:ring-emerald-500/20 bg-slate-50/50">
                <div className="px-3 py-2.5 bg-slate-100 border-r border-slate-200 text-xs font-bold text-slate-600 flex items-center gap-1">
                  <span>🇮🇳</span>
                  <span>+91</span>
                </div>
                <input
                  type="tel"
                  maxLength={10}
                  value={phoneNumber}
                  onChange={(e) => setPhoneNumber(e.target.value)}
                  placeholder="Enter 10-digit mobile number"
                  className="flex-1 px-3 py-2.5 bg-transparent text-sm font-mono font-bold text-slate-900 focus:outline-none"
                />
              </div>
            </div>

            {/* Message Preview */}
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <label className="text-xs font-bold text-slate-700">WhatsApp Message Preview</label>
                <button
                  type="button"
                  onClick={handleCopyText}
                  className="text-[11px] text-emerald-600 font-bold hover:underline flex items-center gap-1 cursor-pointer"
                >
                  {isCopied ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5" />}
                  <span>{isCopied ? "Copied!" : "Copy Text"}</span>
                </button>
              </div>

              <div className="p-3.5 bg-slate-50 rounded-2xl border border-slate-200/80 font-mono text-[11px] text-slate-700 whitespace-pre-wrap leading-relaxed max-h-48 overflow-y-auto">
                {messageText}
              </div>
            </div>
          </div>

          {/* Footer Actions */}
          <div className="p-4 border-t border-slate-100 bg-slate-50/80 flex items-center justify-end gap-2.5">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-xs font-bold text-slate-600 hover:text-slate-900 rounded-xl hover:bg-slate-200 transition-colors cursor-pointer"
            >
              Cancel
            </button>

            <button
              type="button"
              onClick={handleSendWhatsApp}
              className="px-5 py-2.5 bg-[#25D366] hover:bg-[#20bd5a] text-white text-xs font-black rounded-xl shadow-lg shadow-[#25D366]/30 flex items-center gap-2 cursor-pointer transition-all hover:scale-102"
            >
              <Send className="w-4 h-4" />
              <span>Send via WhatsApp</span>
            </button>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
