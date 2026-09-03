"use client";

import React, { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { motion, AnimatePresence } from "motion/react";
import {
  Search,
  LayoutDashboard,
  ShoppingCart,
  Package,
  BookOpen,
  TrendingUp,
  Truck,
  Receipt,
  Settings,
  Plus,
  ArrowRight,
  Sparkles,
  Command,
  X,
  CreditCard,
  Download,
  Printer,
  Users,
} from "lucide-react";

interface CommandPaletteProps {
  isOpen: boolean;
  onClose: () => void;
}

interface CommandItem {
  id: string;
  title: string;
  category: "Navigation" | "Quick Action" | "Record";
  icon: React.ElementType;
  href?: string;
  action?: () => void;
  badge?: string;
}

export function CommandPalette({ isOpen, onClose }: CommandPaletteProps) {
  const router = useRouter();
  const [query, setQuery] = useState("");
  const [selectedIndex, setSelectedIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);

  const commands: CommandItem[] = [
    {
      id: "nav-dashboard",
      title: "Executive Dashboard",
      category: "Navigation",
      icon: LayoutDashboard,
      href: "/",
      badge: "Home",
    },
    {
      id: "nav-pos",
      title: "Live POS Billing Counter (Fast Cashier)",
      category: "Navigation",
      icon: ShoppingCart,
      href: "/pos",
      badge: "F2",
    },
    {
      id: "nav-catalog",
      title: "Master Product Catalog & Barcodes",
      category: "Navigation",
      icon: Package,
      href: "/catalog",
      badge: "SKUs",
    },
    {
      id: "nav-udhaar",
      title: "Udhaar / Khata Credit Ledger",
      category: "Navigation",
      icon: BookOpen,
      href: "/udhaar",
      badge: "Ledger",
    },
    {
      id: "nav-analytics",
      title: "Z-Report & Store Analytics",
      category: "Navigation",
      icon: TrendingUp,
      href: "/analytics",
      badge: "Reports",
    },
    {
      id: "nav-purchases",
      title: "Supplier Purchases & Inward Goods",
      category: "Navigation",
      icon: Truck,
      href: "/purchases",
      badge: "Stock In",
    },
    {
      id: "nav-gst",
      title: "GST Tax Center & GSTR-1 Filings",
      category: "Navigation",
      icon: Receipt,
      href: "/gst",
      badge: "Tax",
    },
    {
      id: "nav-settings",
      title: "Store Settings & Printer Config",
      category: "Navigation",
      icon: Settings,
      href: "/settings",
      badge: "Config",
    },
    {
      id: "action-add-sku",
      title: "Add New Product SKU",
      category: "Quick Action",
      icon: Plus,
      href: "/catalog",
      badge: "Action",
    },
    {
      id: "action-record-payment",
      title: "Record Customer Khata Payment",
      category: "Quick Action",
      icon: CreditCard,
      href: "/udhaar",
      badge: "Khata",
    },
    {
      id: "action-export-gst",
      title: "Download GSTR-1 JSON CA Bundle",
      category: "Quick Action",
      icon: Download,
      href: "/gst",
      badge: "Export",
    },
    {
      id: "action-print-test",
      title: "Test Thermal Slip Printer (58/80mm)",
      category: "Quick Action",
      icon: Printer,
      href: "/settings",
      badge: "Hardware",
    },
  ];

  const filtered = commands.filter((c) =>
    c.title.toLowerCase().includes(query.toLowerCase()) ||
    c.category.toLowerCase().includes(query.toLowerCase())
  );

  useEffect(() => {
    if (isOpen) {
      setTimeout(() => inputRef.current?.focus(), 50);
      setSelectedIndex(0);
      setQuery("");
    }
  }, [isOpen]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "k") {
        e.preventDefault();
        if (isOpen) onClose();
        else {
          // Trigger open
        }
      }

      if (!isOpen) return;

      if (e.key === "Escape") {
        e.preventDefault();
        onClose();
      } else if (e.key === "ArrowDown") {
        e.preventDefault();
        setSelectedIndex((prev) => (prev < filtered.length - 1 ? prev + 1 : 0));
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        setSelectedIndex((prev) => (prev > 0 ? prev - 1 : filtered.length - 1));
      } else if (e.key === "Enter" && filtered[selectedIndex]) {
        e.preventDefault();
        execute(filtered[selectedIndex]);
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, selectedIndex, filtered, onClose]);

  const execute = (item: CommandItem) => {
    onClose();
    if (item.action) {
      item.action();
    } else if (item.href) {
      router.push(item.href);
    }
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-start justify-center pt-20 p-4 select-none">
          {/* Backdrop Blur */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-slate-950/70 backdrop-blur-md"
          />

          {/* Modal Container */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: -10 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: -10 }}
            transition={{ duration: 0.2 }}
            className="w-full max-w-xl bg-slate-900 border border-slate-800 rounded-3xl shadow-2xl shadow-black/90 overflow-hidden relative z-10"
          >
            {/* Search Input Header */}
            <div className="flex items-center px-4 py-3.5 border-b border-slate-800 gap-3">
              <Search className="w-5 h-5 text-emerald-400 shrink-0" />
              <input
                ref={inputRef}
                type="text"
                value={query}
                onChange={(e) => {
                  setQuery(e.target.value);
                  setSelectedIndex(0);
                }}
                placeholder="Type a command, page name, or SKU action..."
                className="w-full bg-transparent text-sm text-white placeholder:text-slate-500 focus:outline-none font-medium"
              />
              <button
                type="button"
                onClick={onClose}
                className="text-slate-500 hover:text-slate-300 p-1 rounded-lg transition-colors cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Results List */}
            <div className="max-h-80 overflow-y-auto p-2 space-y-1">
              {filtered.length === 0 ? (
                <div className="py-12 text-center text-xs text-slate-500">
                  No matching KiranaOS command or record found.
                </div>
              ) : (
                filtered.map((item, idx) => {
                  const Icon = item.icon;
                  const isSelected = idx === selectedIndex;
                  return (
                    <div
                      key={item.id}
                      onClick={() => execute(item)}
                      onMouseEnter={() => setSelectedIndex(idx)}
                      className={`flex items-center justify-between px-3.5 py-2.5 rounded-2xl cursor-pointer transition-all ${
                        isSelected
                          ? "bg-emerald-600/20 border border-emerald-500/40 text-white"
                          : "text-slate-300 hover:bg-slate-800/60 border border-transparent"
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <div
                          className={`p-2 rounded-xl ${
                            isSelected
                              ? "bg-emerald-500 text-white"
                              : "bg-slate-800 text-slate-400"
                          }`}
                        >
                          <Icon className="w-4 h-4" />
                        </div>
                        <div>
                          <p className="text-xs font-bold leading-tight">{item.title}</p>
                          <p className="text-[10px] text-slate-500 font-medium">
                            {item.category}
                          </p>
                        </div>
                      </div>

                      <div className="flex items-center gap-2">
                        {item.badge && (
                          <span className="text-[10px] px-2 py-0.5 rounded-md bg-slate-800 text-slate-400 font-mono font-semibold">
                            {item.badge}
                          </span>
                        )}
                        <ArrowRight
                          className={`w-3.5 h-3.5 transition-opacity ${
                            isSelected ? "text-emerald-400 opacity-100" : "opacity-0"
                          }`}
                        />
                      </div>
                    </div>
                  );
                })
              )}
            </div>

            {/* Modal Footer Key Guide */}
            <div className="flex items-center justify-between px-4 py-2.5 bg-slate-950/60 border-t border-slate-800 text-[11px] text-slate-500">
              <div className="flex items-center gap-3">
                <span>Navigate: <kbd className="px-1.5 py-0.5 bg-slate-800 rounded text-slate-400 font-mono">↑</kbd> <kbd className="px-1.5 py-0.5 bg-slate-800 rounded text-slate-400 font-mono">↓</kbd></span>
                <span>Select: <kbd className="px-1.5 py-0.5 bg-slate-800 rounded text-slate-400 font-mono">↵</kbd></span>
              </div>
              <span>Close: <kbd className="px-1.5 py-0.5 bg-slate-800 rounded text-slate-400 font-mono">ESC</kbd></span>
            </div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}
