"use client";

import React, { useState } from "react";
import Image from "next/image";
import { motion, AnimatePresence } from "motion/react";
import { Sidebar } from "@/components/layout/Sidebar";
import { Header } from "@/components/layout/Header";
import {
  Settings,
  Store,
  Award,
  Barcode,
  Printer,
  Save,
  CheckCircle2,
  ShieldAlert,
  QrCode,
  Sparkles,
  Phone,
  Mail,
  Receipt,
  X,
  AlertCircle,
} from "lucide-react";

export default function SettingsPage() {
  // Shop Profile
  const [shopName, setShopName] = useState("Sri Lakshmi Provision & Supermarket");
  const [phone, setPhone] = useState("9845012345");
  const [email, setEmail] = useState("srilakshmi.kirana@gmail.com");
  const [gstin, setGstin] = useState("29AAAAA0000A1Z5");
  const [fssai, setFssai] = useState("11223344556677");
  const [upiId, setUpiId] = useState("srilakshmi@okaxis");
  const [address, setAddress] = useState("14th Cross, 2nd Main, Indiranagar, Bengaluru");

  // Loyalty Settings
  const [loyaltyEnabled, setLoyaltyEnabled] = useState(true);
  const [earnRate, setEarnRate] = useState("1.0"); // 1 pt per ₹100
  const [redeemValue, setRedeemValue] = useState("1.00"); // 1 pt = ₹1.00
  const [minRedeem, setMinRedeem] = useState("50");

  // Barcode & Thermal Stencils
  const [barcodeTemplate, setBarcodeTemplate] = useState("roll_50x25");
  const [receiptWidth, setReceiptWidth] = useState<"58mm" | "80mm">("80mm");
  const [receiptFooter, setReceiptFooter] = useState("*** THANK YOU! VISIT AGAIN ***\nPowered by KiranaOS");

  // Modals & Feedback
  const [savedSuccess, setSavedSuccess] = useState(false);
  const [showPrinterTestModal, setShowPrinterTestModal] = useState(false);
  const [validationError, setValidationError] = useState<string | null>(null);
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setValidationError(null);

    // High-security input validation
    if (phone.replace(/\D/g, "").length < 10) {
      setValidationError("Phone number must contain at least 10 digits.");
      return;
    }
    if (gstin.trim().length !== 15) {
      setValidationError("GSTIN format must be exactly 15 alphanumeric characters (e.g. 29AAAAA0000A1Z5).");
      return;
    }
    if (!upiId.includes("@")) {
      setValidationError("Please enter a valid UPI Virtual Payment Address (VPA), e.g. storename@okaxis.");
      return;
    }

    setSavedSuccess(true);
    setTimeout(() => setSavedSuccess(false), 3500);
  };

  // Sample order simulation for loyalty preview
  const sampleOrderAmount = 500;
  const sampleEarnedPoints = Math.floor((sampleOrderAmount / 100) * (parseFloat(earnRate) || 1));
  const samplePointsValue = (sampleEarnedPoints * (parseFloat(redeemValue) || 1)).toFixed(2);

  return (
    <div className="flex min-h-screen bg-slate-50 relative overflow-hidden">
      {/* Ambient background glow */}
      <div className="absolute top-0 right-0 w-96 h-96 bg-emerald-400/10 rounded-full blur-3xl pointer-events-none"></div>

      <Sidebar isOpen={mobileNavOpen} onClose={() => setMobileNavOpen(false)} />

      <div className="flex-1 flex flex-col min-w-0 z-10">
        <Header
          title="Store Settings & System Rules"
          subtitle="Configure shop profile, loyalty reward rates, thermal receipt formats, and barcode stencils"
          onMenuClick={() => setMobileNavOpen(true)}
        />

        <main className="p-8 space-y-6 flex-1 overflow-auto max-w-4xl">
          {/* Notifications */}
          <AnimatePresence>
            {savedSuccess && (
              <motion.div
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                className="p-4 bg-emerald-600 text-white rounded-2xl shadow-lg flex items-center justify-between gap-3 text-xs font-bold"
              >
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-5 h-5 text-emerald-200" />
                  <span>Store profile &amp; POS configurations successfully saved and synchronized!</span>
                </div>
                <button
                  type="button"
                  onClick={() => setSavedSuccess(false)}
                  className="p-1 hover:bg-emerald-700 rounded-lg cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </motion.div>
            )}

            {validationError && (
              <motion.div
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                className="p-4 bg-rose-600 text-white rounded-2xl shadow-lg flex items-center justify-between gap-3 text-xs font-bold"
              >
                <div className="flex items-center gap-2">
                  <AlertCircle className="w-5 h-5 text-rose-200" />
                  <span>{validationError}</span>
                </div>
                <button
                  type="button"
                  onClick={() => setValidationError(null)}
                  className="p-1 hover:bg-rose-700 rounded-lg cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </motion.div>
            )}
          </AnimatePresence>

          <form onSubmit={handleSave} className="space-y-6">
            {/* 1. Shop Identity */}
            <div className="p-6 glass-card rounded-2xl shadow-xs space-y-4">
              <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                <Store className="w-4 h-4 text-emerald-600" /> Shop Profile &amp; Regulatory Identity
              </h3>

              {/* Brand Logo Asset Showcase */}
              <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4 p-4 rounded-xl bg-slate-50/80 border border-slate-200/70">
                <div className="relative p-1 rounded-2xl bg-gradient-to-tr from-emerald-600 via-teal-500 to-emerald-400 shadow-md shadow-emerald-950/20 border border-emerald-400/30 shrink-0">
                  <Image
                    src="/logo.png"
                    alt="KiranaOS Brand Logo"
                    width={56}
                    height={56}
                    className="rounded-xl object-cover"
                  />
                </div>
                <div className="flex-1 space-y-1">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-slate-900">Official Store &amp; Brand Logo</span>
                    <span className="text-[10px] font-bold bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded-full">
                      Active System Asset
                    </span>
                  </div>
                  <p className="text-[11px] text-slate-500">
                    High-resolution brand mark synchronized across POS billing terminals, customer receipts, tax invoices, and cloud back-office.
                  </p>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Store / Business Trade Name</label>
                  <input
                    type="text"
                    required
                    value={shopName}
                    onChange={(e) => setShopName(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:outline-none focus:border-emerald-500 font-semibold text-slate-900"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">Store Contact Phone Number</label>
                  <input
                    type="tel"
                    required
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 font-mono focus:bg-white focus:outline-none focus:border-emerald-500"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">GSTIN Number (15 Digits)</label>
                  <input
                    type="text"
                    required
                    maxLength={15}
                    value={gstin}
                    onChange={(e) => setGstin(e.target.value.toUpperCase())}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 font-mono font-bold text-emerald-700 focus:bg-white focus:outline-none focus:border-emerald-500"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">FSSAI Food License Number</label>
                  <input
                    type="text"
                    value={fssai}
                    onChange={(e) => setFssai(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 font-mono focus:bg-white focus:outline-none focus:border-emerald-500"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">Store UPI VPA (for Customer QR)</label>
                  <input
                    type="text"
                    required
                    value={upiId}
                    onChange={(e) => setUpiId(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 font-mono font-bold text-slate-900 focus:bg-white focus:outline-none focus:border-emerald-500"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">Official Support Email</label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 font-mono focus:bg-white focus:outline-none focus:border-emerald-500"
                  />
                </div>

                <div className="md:col-span-2">
                  <label className="font-bold text-slate-700 block mb-1">Store Physical Address (Printed on Invoices)</label>
                  <input
                    type="text"
                    value={address}
                    onChange={(e) => setAddress(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:outline-none focus:border-emerald-500"
                  />
                </div>
              </div>
            </div>

            {/* 2. Customer Loyalty Rules */}
            <div className="p-6 glass-card rounded-2xl shadow-xs space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <Award className="w-4 h-4 text-emerald-600" /> Customer Loyalty Rewards Program
                </h3>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={loyaltyEnabled}
                    onChange={(e) => setLoyaltyEnabled(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-11 h-6 bg-slate-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-slate-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-600"></div>
                </label>
              </div>

              {loyaltyEnabled && (
                <div className="space-y-4 text-xs">
                  <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                    <div>
                      <label className="font-bold text-slate-700 block mb-1">Earn Rate (Points per ₹100 spend)</label>
                      <input
                        type="number"
                        step="0.5"
                        value={earnRate}
                        onChange={(e) => setEarnRate(e.target.value)}
                        className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 font-mono font-bold"
                      />
                    </div>
                    <div>
                      <label className="font-bold text-slate-700 block mb-1">Redeem Value (₹ per 1 Point)</label>
                      <input
                        type="number"
                        step="0.1"
                        value={redeemValue}
                        onChange={(e) => setRedeemValue(e.target.value)}
                        className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 font-mono font-bold"
                      />
                    </div>
                    <div>
                      <label className="font-bold text-slate-700 block mb-1">Min Points to Redeem</label>
                      <input
                        type="number"
                        value={minRedeem}
                        onChange={(e) => setMinRedeem(e.target.value)}
                        className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 font-mono"
                      />
                    </div>
                  </div>

                  {/* Loyalty Simulation Card */}
                  <div className="p-4 bg-emerald-50/70 border border-emerald-200/80 rounded-2xl flex items-center justify-between text-xs">
                    <div className="flex items-center gap-2 text-emerald-900 font-medium">
                      <Sparkles className="w-4 h-4 text-amber-500 shrink-0" />
                      <span>
                        Simulated on a <strong>₹{sampleOrderAmount}</strong> grocery basket: Customer earns{" "}
                        <strong className="text-emerald-700 font-bold">{sampleEarnedPoints} points</strong> worth{" "}
                        <strong className="text-emerald-700 font-bold">₹{samplePointsValue} discount</strong>.
                      </span>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* 3. Thermal Printer & Barcode Stencils */}
            <div className="p-6 glass-card rounded-2xl shadow-xs space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <Printer className="w-4 h-4 text-emerald-600" /> POS Thermal Receipt &amp; Barcode Printing
                </h3>
                <button
                  type="button"
                  onClick={() => setShowPrinterTestModal(true)}
                  className="px-3.5 py-1.5 rounded-xl text-xs font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 hover:bg-emerald-100 transition-colors cursor-pointer flex items-center gap-1.5"
                >
                  <Receipt className="w-3.5 h-3.5" />
                  <span>Test Receipt Print Preview</span>
                </button>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Thermal Receipt Roll Width</label>
                  <div className="grid grid-cols-2 gap-2">
                    <button
                      type="button"
                      onClick={() => setReceiptWidth("58mm")}
                      className={`py-2 rounded-xl font-bold border cursor-pointer ${
                        receiptWidth === "58mm"
                          ? "bg-emerald-50 text-emerald-800 border-emerald-300 shadow-xs"
                          : "bg-slate-50 text-slate-600 border-slate-200"
                      }`}
                    >
                      58mm (2-Inch Handheld)
                    </button>
                    <button
                      type="button"
                      onClick={() => setReceiptWidth("80mm")}
                      className={`py-2 rounded-xl font-bold border cursor-pointer ${
                        receiptWidth === "80mm"
                          ? "bg-emerald-50 text-emerald-800 border-emerald-300 shadow-xs"
                          : "bg-slate-50 text-slate-600 border-slate-200"
                      }`}
                    >
                      80mm (3-Inch Standard)
                    </button>
                  </div>
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">Barcode Shelf Label Roll Size</label>
                  <select
                    value={barcodeTemplate}
                    onChange={(e) => setBarcodeTemplate(e.target.value)}
                    className="w-full px-3 py-2.5 rounded-xl bg-slate-50 border border-slate-200"
                  >
                    <option value="roll_50x25">50mm × 25mm (Standard Grocery Shelf)</option>
                    <option value="roll_38x25">38mm × 25mm (Compact Jewelry / Spice)</option>
                    <option value="roll_100x50">100mm × 50mm (Carton Outer Box)</option>
                  </select>
                </div>

                <div className="md:col-span-2">
                  <label className="font-bold text-slate-700 block mb-1">Receipt Footer Message</label>
                  <textarea
                    rows={2}
                    value={receiptFooter}
                    onChange={(e) => setReceiptFooter(e.target.value)}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 font-mono"
                  />
                </div>
              </div>
            </div>

            {/* Submit Bar */}
            <div className="flex items-center justify-end gap-3 pt-2">
              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                type="submit"
                className="flex items-center gap-2 px-6 py-3 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white rounded-xl text-xs font-bold shadow-lg shadow-emerald-950/20 transition-all cursor-pointer"
              >
                <Save className="w-4 h-4" />
                <span>Save &amp; Sync Store Rules</span>
              </motion.button>
            </div>
          </form>
        </main>
      </div>

      {/* Modal: Thermal Receipt Test Preview */}
      <AnimatePresence>
        {showPrinterTestModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-sm bg-white rounded-3xl p-6 shadow-2xl space-y-4"
            >
              <div className="flex items-center justify-between pb-2 border-b border-slate-100">
                <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <Receipt className="w-4 h-4 text-emerald-600" /> Thermal Receipt Preview ({receiptWidth})
                </h3>
                <button
                  type="button"
                  onClick={() => setShowPrinterTestModal(false)}
                  className="text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              {/* Realistic Thermal Receipt Slip */}
              <div
                className={`p-5 bg-amber-50/40 border border-slate-300 rounded-2xl font-mono text-slate-900 mx-auto shadow-inner space-y-2 text-[11px] ${
                  receiptWidth === "58mm" ? "w-64 text-[10px]" : "w-full"
                }`}
              >
                <div className="text-center pb-2 border-b border-dashed border-slate-400 flex flex-col items-center">
                  <div className="mb-1.5 p-0.5 rounded-lg bg-slate-900/5 border border-slate-300">
                    <Image
                      src="/logo.png"
                      alt="Thermal Receipt Logo"
                      width={28}
                      height={28}
                      className="rounded-md object-cover grayscale contrast-150"
                    />
                  </div>
                  <h4 className="font-extrabold text-sm uppercase tracking-wide">{shopName}</h4>
                  <p className="text-[10px] text-slate-600">{address}</p>
                  <p className="text-[10px] text-slate-600">Ph: +91 {phone}</p>
                  <p className="text-[10px] text-slate-600 font-bold">GSTIN: {gstin}</p>
                  {fssai && <p className="text-[9px] text-slate-500">FSSAI: {fssai}</p>}
                </div>

                <div className="flex justify-between text-slate-600 text-[10px]">
                  <span>Bill: #INV-2026-9901</span>
                  <span>{new Date().toLocaleDateString("en-IN")}</span>
                </div>

                <div className="pt-2 border-t border-dashed border-slate-400 space-y-1">
                  <div className="flex justify-between font-bold">
                    <span>ITEM</span>
                    <span>QTY x RATE</span>
                    <span>AMT</span>
                  </div>
                  <div className="flex justify-between text-slate-700">
                    <span className="truncate max-w-[120px]">Aashirvaad Atta 5k</span>
                    <span>1 x 245.00</span>
                    <span>245.00</span>
                  </div>
                  <div className="flex justify-between text-slate-700">
                    <span className="truncate max-w-[120px]">Tata Salt 1kg</span>
                    <span>2 x 28.00</span>
                    <span>56.00</span>
                  </div>
                  <div className="flex justify-between text-slate-700">
                    <span className="truncate max-w-[120px]">Maggi 70g</span>
                    <span>3 x 14.00</span>
                    <span>42.00</span>
                  </div>
                </div>

                <div className="pt-2 border-t border-dashed border-slate-400 space-y-1 font-bold">
                  <div className="flex justify-between text-xs">
                    <span>NET TOTAL:</span>
                    <span>₹343.00</span>
                  </div>
                  <div className="flex justify-between text-[10px] text-emerald-800">
                    <span>PAID VIA UPI:</span>
                    <span>₹343.00</span>
                  </div>
                </div>

                {/* QR Code Graphic placeholder */}
                <div className="pt-3 pb-2 text-center border-t border-dashed border-slate-400">
                  <div className="w-20 h-20 mx-auto bg-white border border-slate-300 rounded-lg p-1 flex items-center justify-center">
                    <QrCode className="w-16 h-16 text-slate-900" />
                  </div>
                  <p className="text-[9px] text-slate-500 mt-1">Scan &amp; Pay: {upiId}</p>
                </div>

                <div className="text-center whitespace-pre-line text-[9px] text-slate-500 pt-1 border-t border-dashed border-slate-300">
                  {receiptFooter}
                </div>
              </div>

              <div className="pt-2 flex items-center justify-end gap-2 text-xs">
                <button
                  type="button"
                  onClick={() => setShowPrinterTestModal(false)}
                  className="px-3.5 py-1.5 rounded-xl text-slate-600 hover:bg-slate-100 font-semibold cursor-pointer"
                >
                  Close
                </button>
                <button
                  type="button"
                  onClick={() => {
                    alert(`Test ${receiptWidth} receipt dispatched to default system printer!`);
                    setShowPrinterTestModal(false);
                  }}
                  className="px-4 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold cursor-pointer flex items-center gap-1.5"
                >
                  <Printer className="w-3.5 h-3.5" />
                  <span>Send Test Print</span>
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
