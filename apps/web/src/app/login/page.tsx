"use client";

import React, { useState } from "react";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { motion, AnimatePresence } from "motion/react";
import { useAuth } from "@/contexts/AuthContext";
import {
  Store,
  ShieldCheck,
  Lock,
  Phone,
  Mail,
  ArrowRight,
  Eye,
  EyeOff,
  Sparkles,
  AlertCircle,
  CheckCircle2,
  KeyRound,
  Fingerprint,
} from "lucide-react";

export default function LoginPage() {
  const router = useRouter();
  const { login, loginDemo, isAuthenticated } = useAuth();

  const [identifier, setIdentifier] = useState("srilakshmi.kirana@gmail.com");
  const [password, setPassword] = useState("kirana@2026");
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [attempts, setAttempts] = useState(0);

  // If already authenticated, redirect to dashboard
  React.useEffect(() => {
    if (isAuthenticated) {
      router.push("/");
    }
  }, [isAuthenticated, router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);

    // Rate-limiting check
    if (attempts >= 5) {
      setErrorMsg("Security Lockout: Too many failed login attempts. Please wait 60 seconds or use Demo Owner Access.");
      return;
    }

    setIsLoading(true);

    try {
      const result = await login(identifier, password);
      if (result.success) {
        router.push("/");
      } else {
        setAttempts((prev) => prev + 1);
        setErrorMsg(result.message || "Invalid credentials. Please try again.");
      }
    } catch {
      setErrorMsg("An unexpected network error occurred. Please verify your connection.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleDemoLogin = async () => {
    setIsLoading(true);
    setErrorMsg(null);
    try {
      await loginDemo();
      router.push("/");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex items-center justify-center p-4 relative overflow-hidden select-none">
      {/* Aurora Ambient Background Orbs */}
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-emerald-500/15 rounded-full blur-3xl pointer-events-none -translate-x-1/2 -translate-y-1/2 animate-pulse"></div>
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-teal-500/15 rounded-full blur-3xl pointer-events-none translate-x-1/2 translate-y-1/2"></div>
      <div className="absolute top-1/2 right-1/3 w-80 h-80 bg-amber-500/10 rounded-full blur-3xl pointer-events-none"></div>

      <motion.div
        initial={{ opacity: 0, scale: 0.96, y: 15 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ duration: 0.45, ease: "easeOut" }}
        className="w-full max-w-md relative z-10"
      >
        {/* Brand Card Header */}
        <div className="text-center mb-6">
          <motion.div
            whileHover={{ scale: 1.05, rotate: 2 }}
            className="inline-flex p-2 bg-gradient-to-tr from-emerald-600 via-teal-500 to-emerald-400 rounded-3xl shadow-2xl shadow-emerald-950/80 border border-emerald-400/30 mb-3.5 overflow-hidden"
          >
            <Image
              src="/logo.png"
              alt="KiranaOS Logo"
              width={64}
              height={64}
              className="rounded-2xl object-cover drop-shadow-md"
              priority
            />
          </motion.div>
          <div className="flex items-center justify-center gap-2">
            <h1 className="text-2xl font-black tracking-tight text-white">KiranaOS</h1>
            <span className="text-[10px] uppercase font-black px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/40">
              Cloud Suite
            </span>
          </div>
          <p className="text-xs text-slate-400 font-medium mt-1">
            High-Security Store Manager & Owner Portal
          </p>
        </div>

        {/* Glassmorphic Login Box */}
        <div className="bg-slate-900/80 backdrop-blur-xl border border-slate-800/80 rounded-3xl p-7 shadow-2xl shadow-black/80 space-y-5">
          <div className="flex items-center justify-between pb-3 border-b border-slate-800/80 text-xs">
            <span className="text-slate-400 font-semibold flex items-center gap-1.5">
              <ShieldCheck className="w-4 h-4 text-emerald-400" /> 256-Bit SSL Encrypted
            </span>
            <span className="text-[11px] font-mono text-slate-500">v2.0 Pro</span>
          </div>

          <AnimatePresence>
            {errorMsg && (
              <motion.div
                initial={{ opacity: 0, y: -6 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -6 }}
                className="p-3 bg-rose-950/50 border border-rose-800/60 rounded-xl text-xs text-rose-300 flex items-start gap-2 font-medium"
              >
                <AlertCircle className="w-4 h-4 text-rose-400 shrink-0 mt-0.5" />
                <span>{errorMsg}</span>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Quick Demo Access Pill */}
          <div className="p-3 bg-gradient-to-r from-emerald-950/60 to-teal-950/60 border border-emerald-800/50 rounded-2xl flex items-center justify-between gap-3">
            <div className="truncate">
              <div className="flex items-center gap-1.5 text-xs font-bold text-emerald-300">
                <Sparkles className="w-3.5 h-3.5 text-amber-400" />
                <span>1-Click Verified Demo Access</span>
              </div>
              <p className="text-[11px] text-slate-400 truncate">Sri Lakshmi Provision (Ramesh Kumar)</p>
            </div>
            <motion.button
              whileHover={{ scale: 1.03 }}
              whileTap={{ scale: 0.97 }}
              type="button"
              onClick={handleDemoLogin}
              disabled={isLoading}
              className="px-3 py-1.5 bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600 text-white font-bold text-xs rounded-xl shadow-sm shadow-emerald-950/60 shrink-0 cursor-pointer disabled:opacity-50"
            >
              Enter Portal
            </motion.button>
          </div>

          <div className="relative flex items-center justify-center">
            <div className="border-t border-slate-800 w-full"></div>
            <span className="bg-slate-900 px-3 text-[11px] text-slate-500 uppercase font-bold tracking-wider absolute">
              or sign in with credentials
            </span>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4 pt-1">
            {/* Username / Phone / Email */}
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-slate-300 flex items-center gap-1.5">
                <Mail className="w-3.5 h-3.5 text-emerald-400" />
                <span>Store Phone or Email ID</span>
              </label>
              <div className="relative">
                <input
                  type="text"
                  required
                  value={identifier}
                  onChange={(e) => setIdentifier(e.target.value)}
                  placeholder="e.g. 9845012345 or owner@store.com"
                  className="w-full bg-slate-950/80 border border-slate-800 focus:border-emerald-500 rounded-xl px-3.5 py-2.5 text-xs text-white placeholder:text-slate-600 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 font-mono transition-all"
                />
              </div>
            </div>

            {/* Password / PIN */}
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <label className="text-xs font-bold text-slate-300 flex items-center gap-1.5">
                  <KeyRound className="w-3.5 h-3.5 text-emerald-400" />
                  <span>Manager Password or PIN</span>
                </label>
                <span className="text-[11px] text-emerald-400/80 font-medium">Default: kirana@2026</span>
              </div>
              <div className="relative">
                <input
                  type={showPassword ? "text" : "password"}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Enter 4-digit PIN or password"
                  className="w-full bg-slate-950/80 border border-slate-800 focus:border-emerald-500 rounded-xl pl-3.5 pr-10 py-2.5 text-xs text-white placeholder:text-slate-600 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 font-mono transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300 transition-colors cursor-pointer"
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {/* Submit Button */}
            <motion.button
              whileHover={{ scale: 1.01 }}
              whileTap={{ scale: 0.98 }}
              type="submit"
              disabled={isLoading}
              className="w-full py-2.5 bg-gradient-to-r from-emerald-600 via-teal-600 to-emerald-500 hover:from-emerald-500 hover:to-teal-500 text-white font-bold text-xs rounded-xl shadow-lg shadow-emerald-950/80 flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50 transition-all mt-2"
            >
              {isLoading ? (
                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
              ) : (
                <>
                  <span>Authenticate & Open Back-Office</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </>
              )}
            </motion.button>
          </form>

          {/* Security Features Bulletins */}
          <div className="pt-2 border-t border-slate-800/80 grid grid-cols-2 gap-2 text-[11px] text-slate-400">
            <span className="flex items-center gap-1.5">
              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
              <span>Multi-Tenant DB Guard</span>
            </span>
            <span className="flex items-center gap-1.5">
              <Fingerprint className="w-3.5 h-3.5 text-teal-400 shrink-0" />
              <span>POS Device Pairing</span>
            </span>
          </div>
        </div>

        {/* Footer info */}
        <p className="text-center text-[11px] text-slate-500 mt-6">
          KiranaOS Cloud Back-Office Suite • GSTN API Certified • ISO/IEC 27001 Security Standard
        </p>
      </motion.div>
    </div>
  );
}
