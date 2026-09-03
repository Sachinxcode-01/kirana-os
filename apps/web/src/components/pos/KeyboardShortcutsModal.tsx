"use client";

import React from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  Keyboard,
  X,
  Zap,
  ShoppingCart,
  Compass,
  Sparkles,
  Command,
  ArrowRight,
} from "lucide-react";

interface KeyboardShortcutsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

interface ShortcutItem {
  keys: string[];
  action: string;
  description: string;
  badgeColor?: string;
}

export function KeyboardShortcutsModal({ isOpen, onClose }: KeyboardShortcutsModalProps) {
  if (!isOpen) return null;

  const billingShortcuts: ShortcutItem[] = [
    {
      keys: ["/"],
      action: "Focus Barcode / Product Search",
      description: "Instantly ready the scanner or type product name",
      badgeColor: "from-emerald-500 to-teal-500",
    },
    {
      keys: ["+", "-"],
      action: "NumPad Quantity Stepper",
      description: "Increase (+) or decrease (-) quantity of the active cart item",
      badgeColor: "from-teal-500 to-emerald-500",
    },
    {
      keys: ["↑", "↓"],
      action: "Cart Item Navigation",
      description: "Select previous or next line item in the active cart",
      badgeColor: "from-blue-500 to-indigo-500",
    },
    {
      keys: ["Delete"],
      action: "Remove Active Cart Item",
      description: "Deletes selected line item from checkout cart",
      badgeColor: "from-rose-500 to-pink-500",
    },
    {
      keys: ["F4", "Enter"],
      action: "Quick Cash Tender Calculator",
      description: "One-tap denomination chips and instant change return",
      badgeColor: "from-emerald-600 to-teal-600",
    },
    {
      keys: ["F9"],
      action: "Hold / Park Active Bill",
      description: "Suspends cart to serve next customer in line",
      badgeColor: "from-amber-500 to-orange-500",
    },
    {
      keys: ["C"],
      action: "Clear Active Cart",
      description: "Resets checkout counter for a fresh sale",
      badgeColor: "from-slate-600 to-slate-700",
    },
  ];

  const navigationShortcuts: ShortcutItem[] = [
    {
      keys: ["Ctrl", "K"],
      action: "Global Command Palette",
      description: "Search products, customers, suppliers or system actions",
      badgeColor: "from-slate-600 to-slate-700",
    },
    {
      keys: ["?"],
      action: "Open Hotkeys Guide",
      description: "Toggle this counter reference sheet at any time",
      badgeColor: "from-amber-500 to-yellow-500",
    },
    {
      keys: ["Esc"],
      action: "Cancel / Close Active Dialog",
      description: "Clear search, close open modals, or exit screens",
      badgeColor: "from-rose-600 to-rose-700",
    },
  ];

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
          className="absolute inset-0 bg-slate-950/70 backdrop-blur-sm cursor-pointer"
        />

        {/* Modal Window */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 15 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 15 }}
          transition={{ duration: 0.25, ease: "easeOut" }}
          className="relative w-full max-w-2xl bg-slate-900 border border-slate-700/80 rounded-3xl shadow-2xl overflow-hidden z-10 text-slate-100"
        >
          {/* Ambient Top Glow */}
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-3/4 h-24 bg-emerald-500/15 rounded-full blur-3xl pointer-events-none" />

          {/* Modal Header */}
          <div className="flex items-center justify-between p-6 border-b border-slate-800 relative z-10">
            <div className="flex items-center gap-3">
              <div className="p-2.5 bg-gradient-to-br from-emerald-600 to-teal-600 rounded-2xl shadow-md shadow-emerald-950/50 border border-emerald-400/30">
                <Keyboard className="w-5 h-5 text-white" />
              </div>
              <div>
                <h2 className="text-lg font-black text-white flex items-center gap-2">
                  <span>POS Counter Hotkeys</span>
                  <span className="text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-300 border border-emerald-500/40">
                    High-Speed Mode
                  </span>
                </h2>
                <p className="text-xs text-slate-400">
                  Mouse-free shortcuts designed for fast counter operation during peak hours
                </p>
              </div>
            </div>

            <button
              onClick={onClose}
              className="p-2 text-slate-400 hover:text-white rounded-xl hover:bg-slate-800 transition-colors cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Content Body */}
          <div className="p-6 space-y-6 max-h-[70vh] overflow-y-auto">
            {/* Counter & Billing Section */}
            <div className="space-y-3">
              <div className="flex items-center gap-2 text-xs font-bold text-emerald-400 uppercase tracking-wider">
                <ShoppingCart className="w-4 h-4" />
                <span>Express Billing Shortcuts</span>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                {billingShortcuts.map((item, idx) => (
                  <div
                    key={idx}
                    className="p-3 bg-slate-950/60 border border-slate-800/80 rounded-2xl flex items-start justify-between gap-3 hover:border-slate-700 transition-colors"
                  >
                    <div className="space-y-1">
                      <p className="text-xs font-bold text-slate-200">{item.action}</p>
                      <p className="text-[11px] text-slate-400 leading-tight">{item.description}</p>
                    </div>

                    <div className="flex items-center gap-1 shrink-0 pt-0.5">
                      {item.keys.map((k, kIdx) => (
                        <kbd
                          key={kIdx}
                          className="px-2 py-1 text-xs font-mono font-black rounded-lg bg-slate-800 text-emerald-300 border border-slate-700 shadow-sm shadow-black/40 min-w-7 text-center"
                        >
                          {k}
                        </kbd>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Navigation & Controls Section */}
            <div className="space-y-3">
              <div className="flex items-center gap-2 text-xs font-bold text-teal-400 uppercase tracking-wider">
                <Compass className="w-4 h-4" />
                <span>Navigation &amp; System Controls</span>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                {navigationShortcuts.map((item, idx) => (
                  <div
                    key={idx}
                    className="p-3 bg-slate-950/60 border border-slate-800/80 rounded-2xl flex items-start justify-between gap-3 hover:border-slate-700 transition-colors"
                  >
                    <div className="space-y-1">
                      <p className="text-xs font-bold text-slate-200">{item.action}</p>
                      <p className="text-[11px] text-slate-400 leading-tight">{item.description}</p>
                    </div>

                    <div className="flex items-center gap-1 shrink-0 pt-0.5">
                      {item.keys.map((k, kIdx) => (
                        <kbd
                          key={kIdx}
                          className="px-2 py-1 text-xs font-mono font-black rounded-lg bg-slate-800 text-teal-300 border border-slate-700 shadow-sm shadow-black/40 min-w-7 text-center"
                        >
                          {k}
                        </kbd>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Footer Note */}
          <div className="p-4 bg-slate-950/80 border-t border-slate-800 flex items-center justify-between text-xs text-slate-400">
            <div className="flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-amber-400" />
              <span>Tip: Press <kbd className="px-1.5 py-0.5 font-mono text-[11px] bg-slate-800 text-white rounded border border-slate-700">?</kbd> anywhere on screen to toggle this cheat sheet.</span>
            </div>
            <button
              onClick={onClose}
              className="px-3.5 py-1.5 bg-slate-800 hover:bg-slate-700 text-white text-xs font-bold rounded-xl transition-colors cursor-pointer"
            >
              Got it
            </button>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
