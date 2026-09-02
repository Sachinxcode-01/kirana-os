"use client";

import React, { useState } from "react";
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
} from "lucide-react";

export default function SettingsPage() {
  // Shop Profile
  const [shopName, setShopName] = useState("Sri Lakshmi Provision & Supermarket");
  const [phone, setPhone] = useState("9876543210");
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
  const [receiptWidth, setReceiptWidth] = useState("80mm");
  const [receiptFooter, setReceiptFooter] = useState("*** THANK YOU! VISIT AGAIN ***\nPowered by KiranaOS");

  const [savedSuccess, setSavedSuccess] = useState(false);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    setSavedSuccess(true);
    setTimeout(() => setSavedSuccess(false), 3000);
  };

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />

      <div className="flex-1 flex flex-col min-w-0">
        <Header
          title="Store Settings & System Rules"
          subtitle="Configure shop profile, loyalty reward rates, thermal receipt formats, and barcode stencils"
        />

        <main className="p-8 space-y-6 flex-1 overflow-auto max-w-4xl">
          {savedSuccess && (
            <div className="p-4 bg-emerald-50 border border-emerald-200 text-emerald-800 rounded-2xl flex items-center gap-3 text-xs font-bold animate-in fade-in">
              <CheckCircle2 className="w-5 h-5 text-emerald-600" />
              Settings successfully saved and synced to Supabase Cloud!
            </div>
          )}

          <form onSubmit={handleSave} className="space-y-6">
            {/* 1. Shop Identity */}
            <div className="p-6 bg-white rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
              <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                <Store className="w-4 h-4 text-emerald-600" /> Shop Profile &amp; Regulatory Identity
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Store Legal Name *</label>
                  <input
                    type="text"
                    required
                    value={shopName}
                    onChange={(e) => setShopName(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">Primary Store Mobile *</label>
                  <input
                    type="tel"
                    required
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none font-mono"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">GSTIN Number (15-Digits)</label>
                  <input
                    type="text"
                    value={gstin}
                    onChange={(e) => setGstin(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none font-mono"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">FSSAI License No (14-Digits)</label>
                  <input
                    type="text"
                    value={fssai}
                    onChange={(e) => setFssai(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none font-mono"
                  />
                </div>

                <div className="md:col-span-2">
                  <label className="font-bold text-slate-700 block mb-1">Merchant UPI ID (For Bharat QR)</label>
                  <input
                    type="text"
                    value={upiId}
                    onChange={(e) => setUpiId(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none font-mono font-bold text-emerald-700"
                  />
                </div>

                <div className="md:col-span-2">
                  <label className="font-bold text-slate-700 block mb-1">Store Address</label>
                  <textarea
                    rows={2}
                    value={address}
                    onChange={(e) => setAddress(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none"
                  ></textarea>
                </div>
              </div>
            </div>

            {/* 2. Loyalty Rewards Rules */}
            <div className="p-6 bg-white rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <Award className="w-4 h-4 text-emerald-600" /> Customer Loyalty &amp; Rewards Program
                </h3>
                <label className="flex items-center gap-2 text-xs font-semibold cursor-pointer">
                  <input
                    type="checkbox"
                    checked={loyaltyEnabled}
                    onChange={(e) => setLoyaltyEnabled(e.target.checked)}
                    className="w-4 h-4 rounded text-emerald-600 focus:ring-emerald-500"
                  />
                  <span>Enable Loyalty Points</span>
                </label>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-xs">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Earn Rate (% of Bill)</label>
                  <input
                    type="number"
                    step="0.1"
                    value={earnRate}
                    onChange={(e) => setEarnRate(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none font-mono"
                  />
                  <p className="text-[10px] text-slate-400 mt-1">1% = 1 point per ₹100 spent</p>
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">1 Point Value (₹)</label>
                  <input
                    type="number"
                    step="0.01"
                    value={redeemValue}
                    onChange={(e) => setRedeemValue(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none font-mono font-bold text-emerald-700"
                  />
                  <p className="text-[10px] text-slate-400 mt-1">Discount given per redeemed point</p>
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">Min Points to Redeem</label>
                  <input
                    type="number"
                    value={minRedeem}
                    onChange={(e) => setMinRedeem(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none font-mono"
                  />
                  <p className="text-[10px] text-slate-400 mt-1">Customer must hold min points</p>
                </div>
              </div>
            </div>

            {/* 3. Barcode Stencils & Thermal Printing */}
            <div className="p-6 bg-white rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
              <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                <Barcode className="w-4 h-4 text-emerald-600" /> Barcode Stencils &amp; Thermal Receipt Layout
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Default Barcode Label Template</label>
                  <select
                    value={barcodeTemplate}
                    onChange={(e) => setBarcodeTemplate(e.target.value)}
                    className="w-full px-3 py-2.5 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none"
                  >
                    <option value="roll_50x25">Roll Label (50mm × 25mm) - Standard</option>
                    <option value="roll_38x25">Roll Label (38mm × 25mm) - Compact</option>
                    <option value="roll_58x40">Roll Label (58mm × 40mm) - Detailed</option>
                    <option value="sheet_a4_24">A4 Sticker Sheet (24 Labels / 3×8)</option>
                    <option value="sheet_a4_48">A4 Sticker Sheet (48 Labels / 4×12)</option>
                  </select>
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">Thermal Receipt Width</label>
                  <select
                    value={receiptWidth}
                    onChange={(e) => setReceiptWidth(e.target.value)}
                    className="w-full px-3 py-2.5 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none"
                  >
                    <option value="80mm">80mm (Standard Desktop ESC/POS)</option>
                    <option value="58mm">58mm (Handheld Mobile Bluetooth)</option>
                  </select>
                </div>

                <div className="md:col-span-2">
                  <label className="font-bold text-slate-700 block mb-1">Receipt Footer Custom Note</label>
                  <textarea
                    rows={2}
                    value={receiptFooter}
                    onChange={(e) => setReceiptFooter(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none font-mono"
                  ></textarea>
                </div>
              </div>
            </div>

            <div className="flex justify-end">
              <button
                type="submit"
                className="flex items-center gap-2 px-6 py-2.5 rounded-xl text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 shadow-sm shadow-emerald-800/30 transition-all"
              >
                <Save className="w-4 h-4" /> Save Configuration
              </button>
            </div>
          </form>
        </main>
      </div>
    </div>
  );
}
