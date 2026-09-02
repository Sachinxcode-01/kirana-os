"use client";

import React, { useRef, useState, useEffect } from "react";
import { motion } from "motion/react";
import { RefreshCw, CheckCircle2 } from "lucide-react";

interface OtpInputProps {
  length?: number;
  value: string;
  onChange: (otp: string) => void;
  onComplete?: (otp: string) => void;
  onResendOtp?: () => void;
}

export function OtpInput({
  length = 6,
  value,
  onChange,
  onComplete,
  onResendOtp,
}: OtpInputProps) {
  const inputsRef = useRef<(HTMLInputElement | null)[]>([]);
  const [timer, setTimer] = useState(45);
  const [canResend, setCanResend] = useState(false);

  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (timer > 0) {
      interval = setInterval(() => setTimer((prev) => prev - 1), 1000);
    } else {
      setCanResend(true);
    }
    return () => clearInterval(interval);
  }, [timer]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>, idx: number) => {
    const val = e.target.value.replace(/\D/g, "");
    if (!val) {
      const newOtp = value.split("");
      newOtp[idx] = "";
      onChange(newOtp.join(""));
      return;
    }

    const digit = val.slice(-1);
    const newOtp = value.split("");
    newOtp[idx] = digit;
    const combined = newOtp.join("");
    onChange(combined);

    // Auto-advance to next input
    if (idx < length - 1) {
      inputsRef.current[idx + 1]?.focus();
    }

    if (combined.length === length && onComplete) {
      onComplete(combined);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>, idx: number) => {
    if (e.key === "Backspace" && !value[idx] && idx > 0) {
      inputsRef.current[idx - 1]?.focus();
    }
  };

  const handlePaste = (e: React.ClipboardEvent<HTMLInputElement>) => {
    e.preventDefault();
    const pasted = e.clipboardData.getData("text").replace(/\D/g, "").slice(0, length);
    if (pasted) {
      onChange(pasted);
      if (pasted.length === length) {
        inputsRef.current[length - 1]?.focus();
        onComplete?.(pasted);
      } else {
        inputsRef.current[pasted.length]?.focus();
      }
    }
  };

  const handleResend = () => {
    if (!canResend) return;
    setTimer(45);
    setCanResend(false);
    onResendOtp?.();
  };

  return (
    <div className="space-y-3 select-none">
      <div className="flex items-center justify-center gap-2">
        {Array.from({ length }).map((_, idx) => (
          <motion.input
            key={idx}
            ref={(el) => {
              inputsRef.current[idx] = el;
            }}
            whileFocus={{ scale: 1.08, borderColor: "#10b981" }}
            type="text"
            inputMode="numeric"
            maxLength={1}
            value={value[idx] || ""}
            onChange={(e) => handleChange(e, idx)}
            onKeyDown={(e) => handleKeyDown(e, idx)}
            onPaste={handlePaste}
            className="w-11 h-13 bg-slate-950/80 border border-slate-700/80 focus:border-emerald-500 rounded-xl text-center text-xl font-bold font-mono text-white focus:outline-none focus:ring-2 focus:ring-emerald-500/20 transition-all shadow-inner"
          />
        ))}
      </div>

      {/* Countdown and Resend */}
      <div className="flex items-center justify-between text-xs px-1 text-slate-400">
        <span>Instant WhatsApp OTP code</span>
        {canResend ? (
          <button
            type="button"
            onClick={handleResend}
            className="text-emerald-400 hover:text-emerald-300 font-bold flex items-center gap-1 cursor-pointer"
          >
            <RefreshCw className="w-3 h-3" />
            <span>Resend Code</span>
          </button>
        ) : (
          <span className="font-mono text-slate-500">
            Resend in <strong>{timer}s</strong>
          </span>
        )}
      </div>
    </div>
  );
}
