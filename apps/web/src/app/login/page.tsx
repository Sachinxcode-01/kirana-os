"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { motion, AnimatePresence } from "motion/react";
import { useAuth } from "@/contexts/AuthContext";
import { VirtualKeypad } from "@/components/auth/VirtualKeypad";
import { OtpInput } from "@/components/auth/OtpInput";
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
  Smartphone,
  Cpu,
  RefreshCw,
  Zap,
} from "lucide-react";

type AuthMode = "owner" | "cashier" | "otp";

export default function ModernLoginPage() {
  const router = useRouter();
  const { login, loginCashierPin, loginWithOtp, loginWithGoogle, loginDemo, isAuthenticated } = useAuth();

  const [authMode, setAuthMode] = useState<AuthMode>("owner");

  // Owner Form
  const [identifier, setIdentifier] = useState("srilakshmi.kirana@gmail.com");
  const [password, setPassword] = useState("kirana@2026");
  const [showPassword, setShowPassword] = useState(false);

  // Cashier PIN Form
  const [cashierPin, setCashierPin] = useState("1234");
  const [isScrambled, setIsScrambled] = useState(false);

  // OTP Form
  const [otpPhone, setOtpPhone] = useState("9845012345");
  const [otpCode, setOtpCode] = useState("458921");

  // Security & State
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [attempts, setAttempts] = useState(0);
  const [lockoutTimer, setLockoutTimer] = useState(0);

  // Redirect if already authenticated
  useEffect(() => {
    if (isAuthenticated && !isLoading && !isSuccess) {
      router.push("/");
    }
  }, [isAuthenticated, router, isLoading, isSuccess]);

  // Lockout Countdown Timer
  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (lockoutTimer > 0) {
      interval = setInterval(() => {
        setLockoutTimer((prev) => {
          if (prev <= 1) {
            setAttempts(0);
            setErrorMsg(null);
            return 0;
          }
          return prev - 1;
        });
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [lockoutTimer]);

  // Password Entropy Calculator
  const getPasswordStrength = (pass: string) => {
    if (!pass) return { label: "Empty", pct: 0, color: "bg-slate-700" };
    let score = 0;
    if (pass.length >= 6) score += 25;
    if (pass.length >= 10) score += 25;
    if (/[A-Z]/.test(pass)) score += 15;
    if (/[0-9]/.test(pass)) score += 15;
    if (/[^A-Za-z0-9]/.test(pass)) score += 20;

    if (score <= 35) return { label: "Basic", pct: 30, color: "bg-rose-500" };
    if (score <= 65) return { label: "Standard", pct: 60, color: "bg-amber-500" };
    if (score <= 85) return { label: "Strong", pct: 85, color: "bg-emerald-500" };
    return { label: "Enterprise Armor", pct: 100, color: "bg-teal-400" };
  };

  const passwordStrength = getPasswordStrength(password);

  const triggerFailedAttempt = (msg: string) => {
    const newAttempts = attempts + 1;
    setAttempts(newAttempts);
    if (newAttempts >= 5) {
      setLockoutTimer(60);
      setErrorMsg("Security Lockout: 5 consecutive failed attempts. Terminal locked for 60 seconds.");
    } else {
      setErrorMsg(`${msg} (Attempt ${newAttempts} of 5)`);
    }
  };

  const handleOwnerSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (lockoutTimer > 0) return;
    setErrorMsg(null);
    setIsLoading(true);

    try {
      const res = await login(identifier, password);
      if (res.success) {
        setIsSuccess(true);
        setTimeout(() => router.push("/"), 900);
      } else {
        triggerFailedAttempt(res.message || "Invalid credentials.");
      }
    } catch {
      setErrorMsg("Terminal network failure. Please verify cloud database connection.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleCashierSubmit = async (e?: React.FormEvent) => {
    e?.preventDefault();
    if (lockoutTimer > 0) return;
    setErrorMsg(null);
    setIsLoading(true);

    try {
      const res = await loginCashierPin(cashierPin);
      if (res.success) {
        setIsSuccess(true);
        setTimeout(() => router.push("/"), 900);
      } else {
        triggerFailedAttempt(res.message || "Invalid register security PIN.");
      }
    } catch {
      setErrorMsg("POS Terminal pairing communication error.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleOtpSubmit = async (e?: React.FormEvent) => {
    e?.preventDefault();
    if (lockoutTimer > 0) return;
    setErrorMsg(null);
    setIsLoading(true);

    try {
      const res = await loginWithOtp(otpPhone, otpCode);
      if (res.success) {
        setIsSuccess(true);
        setTimeout(() => router.push("/"), 900);
      } else {
        triggerFailedAttempt(res.message || "Invalid 6-digit WhatsApp OTP.");
      }
    } catch {
      setErrorMsg("OTP gateway timeout. Please retry.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleGoogleLogin = async () => {
    setIsLoading(true);
    setErrorMsg(null);
    try {
      const res = await loginWithGoogle();
      if (res.success) {
        setIsSuccess(true);
        setTimeout(() => router.push("/"), 900);
      } else {
        setErrorMsg(res.message || "Google authentication failed.");
      }
    } catch {
      setErrorMsg("Google OAuth network communication error.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleDemoAccess = async () => {
    setIsLoading(true);
    setErrorMsg(null);
    try {
      await loginDemo();
      setIsSuccess(true);
      setTimeout(() => router.push("/"), 900);
    } finally {
      setIsLoading(false);
    }
  };

  const tabs: { id: AuthMode; label: string; icon: React.ElementType }[] = [
    { id: "owner", label: "Store Owner", icon: Store },
    { id: "cashier", label: "Cashier PIN", icon: KeyRound },
    { id: "otp", label: "WhatsApp OTP", icon: Smartphone },
  ];

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex items-center justify-center p-4 relative overflow-hidden select-none">
      {/* Dynamic Aurora Ambient Background Orbs */}
      <div className="absolute top-1/4 left-1/4 w-[520px] h-[520px] bg-emerald-500/15 rounded-full blur-[140px] pointer-events-none -translate-x-1/2 -translate-y-1/2 animate-pulse"></div>
      <div className="absolute bottom-1/4 right-1/4 w-[520px] h-[520px] bg-teal-500/15 rounded-full blur-[140px] pointer-events-none translate-x-1/2 translate-y-1/2"></div>
      <div className="absolute top-1/2 right-1/3 w-[380px] h-[380px] bg-amber-500/8 rounded-full blur-[120px] pointer-events-none"></div>

      {/* Grid Pattern Background Overlay */}
      <div
        className="absolute inset-0 opacity-[0.03] pointer-events-none"
        style={{
          backgroundImage: `radial-gradient(rgba(255, 255, 255, 0.4) 1px, transparent 1px)`,
          backgroundSize: "24px 24px",
        }}
      />

      <motion.div
        initial={{ opacity: 0, scale: 0.96, y: 15 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ duration: 0.45, ease: "easeOut" }}
        className="w-full max-w-lg relative z-10"
      >
        {/* Brand Card Header */}
        <div className="text-center mb-6">
          <motion.div
            whileHover={{ scale: 1.05, rotate: 2 }}
            whileTap={{ scale: 0.98 }}
            className="inline-flex p-3.5 bg-gradient-to-tr from-emerald-600 via-teal-500 to-emerald-400 rounded-3xl shadow-xl shadow-emerald-950/80 border border-emerald-400/40 mb-3.5 glow-emerald"
          >
            <Store className="w-8 h-8 text-white drop-shadow-md" />
          </motion.div>

          <div className="flex items-center justify-center gap-2">
            <h1 className="text-2xl font-black tracking-tight text-white">KiranaOS</h1>
            <span className="text-[10px] uppercase font-black px-2.5 py-0.5 rounded-full bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 shadow-xs shadow-emerald-500/20">
              Enterprise Suite
            </span>
          </div>

          <p className="text-xs text-slate-400 font-medium mt-1">
            Sri Lakshmi Provision &bull; Bengaluru &bull; Counter 01
          </p>
        </div>

        {/* Glassmorphic Login Surface Card */}
        <div className="glass-dark rounded-3xl p-6 sm:p-7 shadow-2xl space-y-5 border border-slate-800/90">
          {/* Top Security & Status Bar */}
          <div className="flex items-center justify-between pb-3.5 border-b border-slate-800/80 text-xs">
            <div className="flex items-center gap-2">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
              </span>
              <span className="text-slate-300 font-bold font-mono text-[11px]">Terminal POS-01</span>
            </div>
            <div className="flex items-center gap-1.5 text-emerald-400 font-semibold text-[11px] bg-emerald-950/60 border border-emerald-800/60 px-2.5 py-0.5 rounded-full">
              <ShieldCheck className="w-3.5 h-3.5" />
              <span>TLS 1.3 Active</span>
            </div>
          </div>

          {/* Lockout & Alert Banners */}
          <AnimatePresence>
            {lockoutTimer > 0 && (
              <motion.div
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: "auto" }}
                exit={{ opacity: 0, height: 0 }}
                className="p-3.5 bg-rose-950/70 border border-rose-800/80 rounded-2xl text-xs text-rose-300 flex items-center justify-between font-bold"
              >
                <div className="flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 text-rose-400 shrink-0" />
                  <span>Security lockout active.</span>
                </div>
                <span className="font-mono text-white bg-rose-900/80 px-2 py-0.5 rounded-lg">
                  {lockoutTimer}s
                </span>
              </motion.div>
            )}

            {errorMsg && lockoutTimer === 0 && (
              <motion.div
                initial={{ opacity: 0, x: -6 }}
                animate={{ opacity: 1, x: [0, -6, 6, -4, 4, 0] }}
                exit={{ opacity: 0, y: -6 }}
                className="p-3 bg-rose-950/60 border border-rose-800/60 rounded-xl text-xs text-rose-300 flex items-start gap-2 font-medium"
              >
                <AlertCircle className="w-4 h-4 text-rose-400 shrink-0 mt-0.5" />
                <span>{errorMsg}</span>
              </motion.div>
            )}

            {isSuccess && (
              <motion.div
                initial={{ opacity: 0, scale: 0.95 }}
                animate={{ opacity: 1, scale: 1 }}
                className="p-3.5 bg-emerald-950/80 border border-emerald-500/80 rounded-2xl text-xs text-emerald-300 flex items-center justify-center gap-2 font-bold"
              >
                <CheckCircle2 className="w-4 h-4 text-emerald-400 animate-bounce" />
                <span>Authentication verified! Launching KiranaOS...</span>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Interactive Mode Sliding Segmented Tabs */}
          <div className="relative p-1 bg-slate-950/90 border border-slate-800/90 rounded-2xl grid grid-cols-3 gap-1">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              const isActive = authMode === tab.id;
              return (
                <button
                  key={tab.id}
                  type="button"
                  onClick={() => {
                    setAuthMode(tab.id);
                    setErrorMsg(null);
                  }}
                  className={`relative py-2.5 rounded-xl text-xs font-bold transition-colors cursor-pointer flex items-center justify-center gap-1.5 z-10 ${
                    isActive ? "text-white" : "text-slate-400 hover:text-slate-200"
                  }`}
                >
                  <Icon className="w-3.5 h-3.5" />
                  <span>{tab.label}</span>

                  {isActive && (
                    <motion.div
                      layoutId="activeAuthTab"
                      transition={{ type: "spring", stiffness: 400, damping: 32 }}
                      className="absolute inset-0 bg-gradient-to-r from-emerald-600 to-teal-600 rounded-xl shadow-md shadow-emerald-950/70 -z-10 border border-emerald-400/30"
                    />
                  )}
                </button>
              );
            })}
          </div>

          {/* Mode 1: Owner / Manager Form */}
          {authMode === "owner" && (
            <motion.form
              key="owner-form"
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              onSubmit={handleOwnerSubmit}
              className="space-y-4 pt-1"
            >
              {/* Username / Phone / Email */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-300 flex items-center gap-1.5">
                  <Mail className="w-3.5 h-3.5 text-emerald-400" />
                  <span>Store Owner ID or Email</span>
                </label>
                <input
                  type="text"
                  required
                  value={identifier}
                  onChange={(e) => setIdentifier(e.target.value)}
                  placeholder="e.g. srilakshmi.kirana@gmail.com"
                  className="w-full glass-input rounded-xl px-3.5 py-2.5 text-xs text-white placeholder:text-slate-600 focus:outline-none font-mono"
                />
              </div>

              {/* Password / Master PIN */}
              <div className="space-y-1.5">
                <div className="flex items-center justify-between">
                  <label className="text-xs font-bold text-slate-300 flex items-center gap-1.5">
                    <Lock className="w-3.5 h-3.5 text-emerald-400" />
                    <span>Master Password</span>
                  </label>
                  <span className="text-[11px] text-emerald-400/90 font-mono bg-emerald-950/40 px-2 py-0.5 rounded border border-emerald-800/40">
                    Default: kirana@2026
                  </span>
                </div>
                <div className="relative">
                  <input
                    type={showPassword ? "text" : "password"}
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Enter master password"
                    className="w-full glass-input rounded-xl pl-3.5 pr-10 py-2.5 text-xs text-white placeholder:text-slate-600 focus:outline-none font-mono"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300 transition-colors cursor-pointer"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>

                {/* Password Entropy Meter */}
                <div className="pt-1.5 space-y-1">
                  <div className="flex justify-between items-center text-[10px] text-slate-400 font-medium">
                    <span>
                      Strength: <strong className="text-slate-200">{passwordStrength.label}</strong>
                    </span>
                    <span>{passwordStrength.pct}%</span>
                  </div>
                  <div className="w-full bg-slate-900/80 h-1.5 rounded-full overflow-hidden border border-slate-800">
                    <motion.div
                      className={`h-full ${passwordStrength.color}`}
                      initial={{ width: 0 }}
                      animate={{ width: `${passwordStrength.pct}%` }}
                      transition={{ duration: 0.3 }}
                    />
                  </div>
                </div>
              </div>

              {/* Submit Button */}
              <motion.button
                whileHover={{ scale: 1.01 }}
                whileTap={{ scale: 0.98 }}
                type="submit"
                disabled={isLoading || lockoutTimer > 0}
                className="w-full py-2.5 bg-gradient-to-r from-emerald-600 via-teal-600 to-emerald-500 hover:from-emerald-500 hover:to-teal-500 text-white font-bold text-xs rounded-xl shadow-lg shadow-emerald-950/80 flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50 transition-all mt-2"
              >
                {isLoading ? (
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                ) : (
                  <>
                    <span>Authenticate &amp; Open Back-Office</span>
                    <ArrowRight className="w-3.5 h-3.5" />
                  </>
                )}
              </motion.button>
            </motion.form>
          )}

          {/* Mode 2: Cashier Register Quick PIN */}
          {authMode === "cashier" && (
            <motion.div
              key="cashier-mode"
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              className="space-y-4 pt-1"
            >
              <div className="text-center space-y-1">
                <p className="text-xs font-bold text-slate-200">Cashier Counter Quick-PIN</p>
                <p className="text-[11px] text-slate-400">
                  Default PIN: <strong className="font-mono text-emerald-400 bg-emerald-950/40 px-2 py-0.5 rounded border border-emerald-800/40">1234</strong>
                </p>
              </div>

              {/* Masked PIN Display */}
              <div className="flex items-center justify-center gap-3 py-1">
                {[0, 1, 2, 3].map((idx) => (
                  <div
                    key={idx}
                    className={`w-11 h-11 rounded-2xl border flex items-center justify-center text-xl font-bold font-mono transition-all ${
                      cashierPin[idx]
                        ? "border-emerald-500 bg-emerald-950/60 text-emerald-300 shadow-md shadow-emerald-950/60 glow-emerald"
                        : "border-slate-800 bg-slate-950/80 text-slate-600"
                    }`}
                  >
                    {cashierPin[idx] ? "●" : ""}
                  </div>
                ))}
              </div>

              {/* On-Screen Virtual Touch Keypad */}
              <VirtualKeypad
                isScrambled={isScrambled}
                onToggleScramble={() => setIsScrambled(!isScrambled)}
                onDigit={(d) => {
                  if (cashierPin.length < 4) {
                    setCashierPin((prev) => prev + d);
                  }
                }}
                onDelete={() => setCashierPin((prev) => prev.slice(0, -1))}
                onClear={() => setCashierPin("")}
              />

              <motion.button
                whileHover={{ scale: 1.01 }}
                whileTap={{ scale: 0.98 }}
                type="button"
                onClick={() => handleCashierSubmit()}
                disabled={isLoading || cashierPin.length < 4 || lockoutTimer > 0}
                className="w-full py-2.5 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white font-bold text-xs rounded-xl shadow-lg shadow-emerald-950/80 flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50 transition-all"
              >
                {isLoading ? (
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                ) : (
                  <>
                    <span>Unlock Register Terminal</span>
                    <ArrowRight className="w-3.5 h-3.5" />
                  </>
                )}
              </motion.button>
            </motion.div>
          )}

          {/* Mode 3: WhatsApp OTP Verification */}
          {authMode === "otp" && (
            <motion.div
              key="otp-mode"
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              className="space-y-4 pt-1"
            >
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-300 flex items-center gap-1.5">
                  <Phone className="w-3.5 h-3.5 text-emerald-400" />
                  <span>Registered Mobile Number</span>
                </label>
                <input
                  type="tel"
                  required
                  value={otpPhone}
                  onChange={(e) => setOtpPhone(e.target.value)}
                  placeholder="e.g. 9845012345"
                  className="w-full glass-input rounded-xl px-3.5 py-2.5 text-xs text-white placeholder:text-slate-600 focus:outline-none font-mono"
                />
              </div>

              {/* 6-Digit Auto-Advancing OTP Input */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-300">Enter 6-Digit Verification Code</label>
                <OtpInput
                  length={6}
                  value={otpCode}
                  onChange={setOtpCode}
                  onComplete={() => handleOtpSubmit()}
                  onResendOtp={() => setErrorMsg("New verification code dispatched via WhatsApp.")}
                />
              </div>

              <motion.button
                whileHover={{ scale: 1.01 }}
                whileTap={{ scale: 0.98 }}
                type="button"
                onClick={() => handleOtpSubmit()}
                disabled={isLoading || otpCode.length < 6 || lockoutTimer > 0}
                className="w-full py-2.5 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white font-bold text-xs rounded-xl shadow-lg shadow-emerald-950/80 flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50 transition-all mt-2"
              >
                {isLoading ? (
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                ) : (
                  <>
                    <span>Verify Code &amp; Log In</span>
                    <ArrowRight className="w-3.5 h-3.5" />
                  </>
                )}
              </motion.button>
            </motion.div>
          )}

          {/* Clean Divider */}
          <div className="relative flex items-center justify-center pt-1">
            <div className="border-t border-slate-800 w-full" />
            <span className="bg-slate-900 px-3 text-[10px] uppercase tracking-widest text-slate-500 font-bold absolute">
              Or Instant Access
            </span>
          </div>

          {/* Quick 1-Click Demo Access Pill */}
          <div className="p-3 bg-gradient-to-r from-emerald-950/50 via-slate-900 to-teal-950/50 border border-emerald-800/40 rounded-2xl flex items-center justify-between gap-3">
            <div className="truncate">
              <div className="flex items-center gap-1.5 text-xs font-bold text-emerald-300">
                <Sparkles className="w-3.5 h-3.5 text-amber-400 animate-pulse" />
                <span>1-Click Verified Store Passkey</span>
              </div>
              <p className="text-[11px] text-slate-400 truncate">Ramesh Kumar &bull; Sri Lakshmi Provision</p>
            </div>
            <motion.button
              whileHover={{ scale: 1.03 }}
              whileTap={{ scale: 0.97 }}
              type="button"
              onClick={handleDemoAccess}
              disabled={isLoading || lockoutTimer > 0}
              className="px-3.5 py-1.5 bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600 text-white font-bold text-xs rounded-xl shadow-md shadow-emerald-950/60 shrink-0 cursor-pointer disabled:opacity-50"
            >
              Sign In Now
            </motion.button>
          </div>

          {/* Sign In With Google */}
          <motion.button
            whileHover={{ scale: 1.01 }}
            whileTap={{ scale: 0.98 }}
            type="button"
            onClick={handleGoogleLogin}
            disabled={isLoading || lockoutTimer > 0}
            className="w-full py-2.5 bg-slate-900 hover:bg-slate-850 text-slate-200 font-semibold text-xs rounded-xl shadow-sm flex items-center justify-center gap-2.5 cursor-pointer disabled:opacity-50 transition-all border border-slate-800"
          >
            <svg className="w-4 h-4" viewBox="0 0 24 24">
              <path
                fill="#4285F4"
                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
              />
              <path
                fill="#34A853"
                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
              />
              <path
                fill="#FBBC05"
                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
              />
              <path
                fill="#EA4335"
                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
              />
            </svg>
            <span>Continue with Google Workspace</span>
          </motion.button>

          {/* Security Features Bulletins */}
          <div className="pt-2 border-t border-slate-800/80 grid grid-cols-2 gap-2 text-[11px] text-slate-400">
            <span className="flex items-center gap-1.5">
              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
              <span>Zero-Knowledge Encryption</span>
            </span>
            <span className="flex items-center gap-1.5">
              <Fingerprint className="w-3.5 h-3.5 text-teal-400 shrink-0" />
              <span>POS Hardware Key Tagged</span>
            </span>
          </div>
        </div>

        {/* Footer info */}
        <p className="text-center text-[11px] text-slate-500 mt-5">
          KiranaOS Cloud Back-Office Suite &bull; GSTN API Certified &bull; ISO/IEC 27001 Security Standard
        </p>
      </motion.div>
    </div>
  );
}
