"use client";

import React, { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  UserPlus,
  X,
  Phone,
  User,
  CreditCard,
  MapPin,
  CheckCircle2,
  AlertCircle,
  Sparkles,
  MessageSquare,
} from "lucide-react";

import { posAudio } from "@/utils/audioFeedback";

export interface NewCustomerData {
  id: string;
  name: string;
  phone: string;
  creditLimitPaise: number;
  currentBalancePaise: number;
  loyaltyPoints: number;
  address?: string;
}

interface QuickCustomerModalProps {
  isOpen: boolean;
  onClose: () => void;
  onCustomerCreated: (customer: NewCustomerData) => void;
  existingPhones?: string[];
}

export function QuickCustomerModal({
  isOpen,
  onClose,
  onCustomerCreated,
  existingPhones = [],
}: QuickCustomerModalProps) {
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [creditLimitRupees, setCreditLimitRupees] = useState<number>(5000);
  const [address, setAddress] = useState("");
  const [notifyWhatsApp, setNotifyWhatsApp] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isSuccess, setIsSuccess] = useState(false);

  const nameInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (isOpen) {
      setName("");
      setPhone("");
      setCreditLimitRupees(5000);
      setAddress("");
      setError(null);
      setIsSuccess(false);

      setTimeout(() => {
        nameInputRef.current?.focus();
      }, 100);
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handlePhoneChange = (val: string) => {
    // Only numbers, max 10 digits
    const cleaned = val.replace(/\D/g, "").slice(0, 10);
    setPhone(cleaned);
    if (error) setError(null);
  };

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();

    if (!name.trim()) {
      setError("Customer name is required.");
      posAudio.playWarningBuzzer();
      return;
    }

    if (!/^[6-9]\d{9}$/.test(phone)) {
      setError("Enter a valid 10-digit Indian mobile number starting with 6, 7, 8, or 9.");
      posAudio.playWarningBuzzer();
      return;
    }

    if (existingPhones.includes(phone)) {
      setError("A customer with this mobile number already exists in your ledger.");
      posAudio.playWarningBuzzer();
      return;
    }

    const newCustomer: NewCustomerData = {
      id: `c-${Date.now()}`,
      name: name.trim(),
      phone: phone.trim(),
      creditLimitPaise: creditLimitRupees * 100,
      currentBalancePaise: 0,
      loyaltyPoints: 50, // Welcome loyalty bonus points
      address: address.trim() || undefined,
    };

    posAudio.playSuccessChime();
    setIsSuccess(true);

    setTimeout(() => {
      onCustomerCreated(newCustomer);
      onClose();
    }, 900);
  };

  const creditPresets = [2000, 5000, 10000, 20000, 50000];

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

        {/* Modal Content */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 15 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 15 }}
          transition={{ duration: 0.2, ease: "easeOut" }}
          className="relative w-full max-w-lg bg-slate-900 border border-slate-700/80 rounded-3xl shadow-2xl overflow-hidden z-10 text-slate-100"
        >
          {/* Ambient Top Glow */}
          <div className="absolute top-0 right-1/4 w-64 h-28 bg-emerald-500/15 rounded-full blur-3xl pointer-events-none" />

          {/* Modal Header */}
          <div className="flex items-center justify-between p-5 border-b border-slate-800 relative z-10">
            <div className="flex items-center gap-3">
              <div className="p-2.5 bg-gradient-to-br from-emerald-600 to-teal-600 rounded-2xl shadow-md shadow-emerald-950/50 border border-emerald-400/30">
                <UserPlus className="w-5 h-5 text-white" />
              </div>
              <div>
                <h2 className="text-base font-black text-white flex items-center gap-2">
                  <span>Register In-Store Customer</span>
                  <kbd className="px-1.5 py-0.5 text-[10px] font-mono font-bold rounded bg-slate-800 text-emerald-300 border border-slate-700">
                    F3
                  </kbd>
                </h2>
                <p className="text-xs text-slate-400">Attach customer for Khata credit ledger &amp; loyalty bonus</p>
              </div>
            </div>

            <button
              onClick={onClose}
              className="p-2 text-slate-400 hover:text-white rounded-xl hover:bg-slate-800 transition-colors cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Success Banner */}
          {isSuccess ? (
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              className="p-10 text-center space-y-3"
            >
              <div className="w-14 h-14 mx-auto bg-emerald-500/20 border border-emerald-500/40 rounded-full flex items-center justify-center text-emerald-400">
                <CheckCircle2 className="w-8 h-8 animate-bounce" />
              </div>
              <h3 className="text-lg font-black text-white">Customer Account Created!</h3>
              <p className="text-xs text-slate-300">
                {name} (+91 {phone}) linked to active billing session with +50 loyalty pts.
              </p>
            </motion.div>
          ) : (
            /* Registration Form */
            <form onSubmit={handleCreate} className="p-6 space-y-4">
              {error && (
                <div className="p-3 bg-rose-950/60 border border-rose-800/80 rounded-xl text-rose-300 text-xs flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0 text-rose-400" />
                  <span>{error}</span>
                </div>
              )}

              {/* Name Field */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-300 flex items-center gap-1.5">
                  <User className="w-3.5 h-3.5 text-emerald-400" /> Full Name *
                </label>
                <input
                  ref={nameInputRef}
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g. Ramesh Kumar"
                  className="w-full px-3.5 py-2.5 bg-slate-950 border border-slate-700/80 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500 font-medium"
                />
              </div>

              {/* Phone Field */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-300 flex items-center gap-1.5">
                  <Phone className="w-3.5 h-3.5 text-emerald-400" /> Mobile Number (10 Digits) *
                </label>
                <div className="flex items-center">
                  <span className="px-3 py-2.5 bg-slate-800 border border-r-0 border-slate-700 rounded-l-xl text-xs font-mono font-bold text-slate-300">
                    +91
                  </span>
                  <input
                    type="tel"
                    value={phone}
                    onChange={(e) => handlePhoneChange(e.target.value)}
                    placeholder="9876543210"
                    className="w-full px-3.5 py-2.5 bg-slate-950 border border-slate-700/80 rounded-r-xl text-sm font-mono text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500 font-medium"
                  />
                </div>
              </div>

              {/* Khata Credit Limit */}
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <label className="text-xs font-bold text-slate-300 flex items-center gap-1.5">
                    <CreditCard className="w-3.5 h-3.5 text-amber-400" /> Khata Credit Limit (₹)
                  </label>
                  <span className="text-xs font-mono font-bold text-amber-300">
                    ₹{creditLimitRupees.toLocaleString("en-IN")}
                  </span>
                </div>

                <div className="grid grid-cols-5 gap-1.5">
                  {creditPresets.map((preset) => (
                    <button
                      key={preset}
                      type="button"
                      onClick={() => setCreditLimitRupees(preset)}
                      className={`py-1.5 text-center text-xs font-mono font-bold rounded-lg border transition-all cursor-pointer ${
                        creditLimitRupees === preset
                          ? "bg-amber-500/20 border-amber-500 text-amber-300 ring-1 ring-amber-500/30"
                          : "bg-slate-800/80 border-slate-700 text-slate-300 hover:border-slate-600"
                      }`}
                    >
                      ₹{preset >= 1000 ? `${preset / 1000}k` : preset}
                    </button>
                  ))}
                </div>
              </div>

              {/* Address / Landmark */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-300 flex items-center gap-1.5">
                  <MapPin className="w-3.5 h-3.5 text-slate-400" /> Delivery Address / Notes (Optional)
                </label>
                <input
                  type="text"
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  placeholder="e.g. Flat 302, Green Valley Apts or Near Shiv Temple"
                  className="w-full px-3.5 py-2 bg-slate-950 border border-slate-700/80 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500"
                />
              </div>

              {/* Loyalty & WhatsApp Option */}
              <div className="p-3 bg-slate-950/80 border border-slate-800 rounded-xl flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="p-1.5 bg-teal-500/20 text-teal-300 rounded-lg">
                    <Sparkles className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-xs font-bold text-slate-200">Welcome Loyalty Bonus</p>
                    <p className="text-[10px] text-teal-400">+50 points credited automatically</p>
                  </div>
                </div>

                <label className="flex items-center gap-2 cursor-pointer text-xs text-slate-300">
                  <input
                    type="checkbox"
                    checked={notifyWhatsApp}
                    onChange={(e) => setNotifyWhatsApp(e.target.checked)}
                    className="w-4 h-4 accent-emerald-500 rounded cursor-pointer"
                  />
                  <span className="flex items-center gap-1 text-[11px] text-slate-300">
                    <MessageSquare className="w-3 h-3 text-emerald-400" /> WhatsApp
                  </span>
                </label>
              </div>

              {/* Action Buttons */}
              <div className="flex items-center gap-2 pt-2">
                <button
                  type="button"
                  onClick={onClose}
                  className="w-1/3 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-bold rounded-xl transition-colors cursor-pointer"
                >
                  Cancel (Esc)
                </button>
                <button
                  type="submit"
                  className="w-2/3 py-2.5 bg-gradient-to-r from-emerald-600 via-teal-600 to-emerald-500 hover:from-emerald-500 hover:to-teal-500 text-white text-xs font-black rounded-xl shadow-lg shadow-emerald-950/80 flex items-center justify-center gap-2 cursor-pointer transition-all"
                >
                  <UserPlus className="w-4 h-4" />
                  <span>Register &amp; Link Customer</span>
                </button>
              </div>
            </form>
          )}
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
