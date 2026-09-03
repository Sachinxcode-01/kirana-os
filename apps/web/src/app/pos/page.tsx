"use client";

import React, { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Sidebar } from "@/components/layout/Sidebar";
import { Header } from "@/components/layout/Header";
import {
  ShoppingCart,
  Barcode,
  Search,
  Plus,
  Minus,
  Trash2,
  Users,
  CreditCard,
  Banknote,
  Receipt,
  RotateCcw,
  Clock,
  CheckCircle2,
  AlertCircle,
  Tag,
  Sparkles,
  PauseCircle,
  PlayCircle,
  Printer,
  Send,
  X,
  Keyboard,
  ArrowRight,
  ShieldCheck,
  ChevronDown,
  Percent,
  Coins,
  Package,
  UserPlus,
} from "lucide-react";
import { WebProduct, WebCustomer, WebCartItem, WebHeldBill } from "@/types";
import { QuickTenderModal } from "@/components/pos/QuickTenderModal";
import { ThermalReceiptModal } from "@/components/pos/ThermalReceiptModal";
import { WhatsAppInvoiceModal } from "@/components/pos/WhatsAppInvoiceModal";
import { KeyboardShortcutsModal } from "@/components/pos/KeyboardShortcutsModal";
import { QuickCustomerModal, NewCustomerData } from "@/components/pos/QuickCustomerModal";
import { VoiceSearchButton } from "@/components/pos/VoiceSearchButton";
import { posAudio } from "@/utils/audioFeedback";
import { useLanguage } from "@/contexts/LanguageContext";

// Initial Catalog Inventory
const INVENTORY_ITEMS: WebProduct[] = [
  {
    id: "p1",
    name: "Aashirvaad Shudh Chakki Atta 5kg",
    categoryName: "Atta & Flours",
    unit: "packet",
    sellingPricePaise: 24500,
    mrpPaise: 26000,
    costPricePaise: 22000,
    taxRate: 0.0,
    currentStock: 45,
    minStockThreshold: 10,
    hsnCode: "1101",
    barcode: "8901030383793",
    isActive: true,
  },
  {
    id: "p2",
    name: "Fortune Sunlite Refined Sunflower Oil 1L",
    categoryName: "Edible Oils & Ghee",
    unit: "packet",
    sellingPricePaise: 13500,
    mrpPaise: 15000,
    costPricePaise: 12000,
    taxRate: 5.0,
    currentStock: 60,
    minStockThreshold: 15,
    hsnCode: "1512",
    barcode: "8906007281014",
    isActive: true,
  },
  {
    id: "p3",
    name: "Amul Pasteurised Butter 500g",
    categoryName: "Dairy & Spreads",
    unit: "packet",
    sellingPricePaise: 27500,
    mrpPaise: 28500,
    costPricePaise: 25000,
    taxRate: 12.0,
    currentStock: 8,
    minStockThreshold: 10,
    hsnCode: "0405",
    barcode: "8901262010054",
    isActive: true,
  },
  {
    id: "p4",
    name: "Tata Salt Vacuum Evaporated 1kg",
    categoryName: "Spices & Salt",
    unit: "packet",
    sellingPricePaise: 2800,
    mrpPaise: 3000,
    costPricePaise: 2400,
    taxRate: 0.0,
    currentStock: 120,
    minStockThreshold: 20,
    hsnCode: "2501",
    barcode: "8904043901005",
    isActive: true,
  },
  {
    id: "p5",
    name: "India Gate Basmati Rice Feast Rozzana 1kg",
    categoryName: "Rice & Grains",
    unit: "packet",
    sellingPricePaise: 9500,
    mrpPaise: 11000,
    costPricePaise: 8200,
    taxRate: 0.0,
    currentStock: 35,
    minStockThreshold: 8,
    hsnCode: "1006",
    barcode: "8901396001017",
    isActive: true,
  },
  {
    id: "p6",
    name: "Loose Premium Toor Dal (Polished)",
    categoryName: "Pulses & Dals",
    unit: "kg",
    sellingPricePaise: 16500,
    mrpPaise: 18000,
    costPricePaise: 14500,
    taxRate: 0.0,
    currentStock: 85,
    minStockThreshold: 15,
    hsnCode: "0713",
    barcode: "2000010000001",
    isActive: true,
  },
  {
    id: "p7",
    name: "Loose Madhur Refined Sugar M-30",
    categoryName: "Atta & Flours",
    unit: "kg",
    sellingPricePaise: 4400,
    mrpPaise: 4800,
    costPricePaise: 3800,
    taxRate: 0.0,
    currentStock: 210,
    minStockThreshold: 30,
    hsnCode: "1701",
    barcode: "2000020000008",
    isActive: true,
  },
  {
    id: "p8",
    name: "Brooke Bond Red Label Tea 500g",
    categoryName: "Beverages & Tea",
    unit: "packet",
    sellingPricePaise: 26000,
    mrpPaise: 28000,
    costPricePaise: 23500,
    taxRate: 5.0,
    currentStock: 3,
    minStockThreshold: 10,
    hsnCode: "0902",
    barcode: "8901030010323",
    isActive: true,
  },
  {
    id: "p9",
    name: "Surf Excel Easy Wash Detergent Powder 1kg",
    categoryName: "Household & Soaps",
    unit: "packet",
    sellingPricePaise: 14000,
    mrpPaise: 15500,
    costPricePaise: 12200,
    taxRate: 18.0,
    currentStock: 40,
    minStockThreshold: 10,
    hsnCode: "3402",
    barcode: "8901030431203",
    isActive: true,
  },
  {
    id: "p10",
    name: "Parle-G Gold Biscuits 1kg Value Pack",
    categoryName: "Biscuits & Snacks",
    unit: "packet",
    sellingPricePaise: 9000,
    mrpPaise: 10000,
    costPricePaise: 7800,
    taxRate: 18.0,
    currentStock: 50,
    minStockThreshold: 12,
    hsnCode: "1905",
    barcode: "8901719101038",
    isActive: true,
  },
];

const CUSTOMERS_LIST: WebCustomer[] = [
  {
    id: "c-walkin",
    name: "Walk-in Retail Customer",
    phone: "9999999999",
    creditLimitPaise: 0,
    currentBalancePaise: 0,
    loyaltyPoints: 0,
  },
  {
    id: "c1",
    name: "Anil Sharma",
    phone: "9880011223",
    creditLimitPaise: 500000,
    currentBalancePaise: 185000,
    loyaltyPoints: 120,
  },
  {
    id: "c2",
    name: "Sunita Patel",
    phone: "9880044556",
    creditLimitPaise: 1000000,
    currentBalancePaise: 820000,
    loyaltyPoints: 250,
  },
  {
    id: "c3",
    name: "Rajesh Verma",
    phone: "9880077889",
    creditLimitPaise: 300000,
    currentBalancePaise: 0,
    loyaltyPoints: 45,
  },
];

const CATEGORIES = [
  "All",
  "Atta & Flours",
  "Edible Oils & Ghee",
  "Dairy & Spreads",
  "Pulses & Dals",
  "Rice & Grains",
  "Spices & Salt",
  "Beverages & Tea",
  "Biscuits & Snacks",
  "Household & Soaps",
];

export default function PosBillingPage() {
  const { t } = useLanguage();
  const searchInputRef = useRef<HTMLInputElement>(null);

  // Layout State
  const [mobileNavOpen, setMobileNavOpen] = useState(false);
  const [currentTime, setCurrentTime] = useState("");

  // POS State
  const [cart, setCart] = useState<WebCartItem[]>([
    {
      id: "cart-item-1",
      productId: "p1",
      name: "Aashirvaad Shudh Chakki Atta 5kg",
      unit: "packet",
      quantity: 1,
      unitPricePaise: 24500,
      mrpPaise: 26000,
      discountPaise: 0,
      taxRate: 0.0,
      hsnCode: "1101",
      barcode: "8901030383793",
    },
    {
      id: "cart-item-2",
      productId: "p5",
      name: "India Gate Basmati Rice Feast Rozzana 1kg",
      unit: "packet",
      quantity: 1,
      unitPricePaise: 9500,
      mrpPaise: 11000,
      discountPaise: 0,
      taxRate: 0.0,
      hsnCode: "1006",
      barcode: "8901396001017",
    },
  ]);

  const [selectedCategory, setSelectedCategory] = useState("All");
  const [searchQuery, setSearchQuery] = useState("");
  const [customersList, setCustomersList] = useState<WebCustomer[]>(CUSTOMERS_LIST);
  const [selectedCustomer, setSelectedCustomer] = useState<WebCustomer>(CUSTOMERS_LIST[0]);
  const [billSequence, setBillSequence] = useState(43);
  const [heldBills, setHeldBills] = useState<WebHeldBill[]>([]);
  const [scanToast, setScanToast] = useState<string | null>(null);
  const [selectedCartIndex, setSelectedCartIndex] = useState<number>(0);

  // Modals
  const [tenderOpen, setTenderOpen] = useState(false);
  const [receiptOpen, setReceiptOpen] = useState(false);
  const [whatsAppOpen, setWhatsAppOpen] = useState(false);
  const [shortcutsOpen, setShortcutsOpen] = useState(false);
  const [customerModalOpen, setCustomerModalOpen] = useState(false);
  const [completedInvoice, setCompletedInvoice] = useState<any>(null);

  // Real-time clock update
  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setCurrentTime(
        now.toLocaleTimeString("en-IN", {
          hour: "2-digit",
          minute: "2-digit",
          second: "2-digit",
          hour12: true,
        })
      );
    };
    updateTime();
    const interval = setInterval(updateTime, 1000);
    return () => clearInterval(interval);
  }, []);

  // Global Keyboard Shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Don't trigger if user is inside a modal
      if (tenderOpen || receiptOpen || whatsAppOpen || shortcutsOpen || customerModalOpen) {
        if (e.key === "Escape") {
          setTenderOpen(false);
          setReceiptOpen(false);
          setWhatsAppOpen(false);
          setShortcutsOpen(false);
          setCustomerModalOpen(false);
        }
        return;
      }

      const isInput = e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement;

      if (e.key === "F2") {
        e.preventDefault();
        searchInputRef.current?.focus();
        searchInputRef.current?.select();
      } else if (e.key === "F3") {
        e.preventDefault();
        setCustomerModalOpen(true);
      } else if (e.key === "F4") {
        e.preventDefault();
        if (cart.length > 0) {
          posAudio.beepSuccess();
          setTenderOpen(true);
        } else {
          posAudio.beepError();
          showNotification("Cart is empty! Add items before tender.");
        }
      } else if (e.key === "F9") {
        e.preventDefault();
        handleHoldBill();
      } else if (e.key === "?") {
        if (!isInput) {
          e.preventDefault();
          setShortcutsOpen(true);
        }
      } else if (!isInput) {
        // NumPad & Single-Key POS Ergonomics (Phase 19.2)
        if (e.key === "+" || e.key === "=") {
          e.preventDefault();
          if (cart.length > 0 && selectedCartIndex >= 0 && selectedCartIndex < cart.length) {
            updateQuantity(cart[selectedCartIndex].id, 1);
          }
        } else if (e.key === "-" || e.key === "_") {
          e.preventDefault();
          if (cart.length > 0 && selectedCartIndex >= 0 && selectedCartIndex < cart.length) {
            updateQuantity(cart[selectedCartIndex].id, -1);
          }
        } else if (e.key === "Delete" || e.key === "Backspace") {
          e.preventDefault();
          if (cart.length > 0 && selectedCartIndex >= 0 && selectedCartIndex < cart.length) {
            removeItem(cart[selectedCartIndex].id);
            setSelectedCartIndex((prev) => Math.max(0, Math.min(prev, cart.length - 2)));
          }
        } else if (e.key === "ArrowUp") {
          e.preventDefault();
          setSelectedCartIndex((prev) => Math.max(0, prev - 1));
        } else if (e.key === "ArrowDown") {
          e.preventDefault();
          setSelectedCartIndex((prev) => Math.min(cart.length - 1, prev + 1));
        } else if (e.key === "/") {
          e.preventDefault();
          searchInputRef.current?.focus();
          searchInputRef.current?.select();
        } else if (e.key.toLowerCase() === "c") {
          e.preventDefault();
          clearCart();
        } else if (e.key === "Enter") {
          e.preventDefault();
          if (cart.length > 0) {
            posAudio.beepSuccess();
            setTenderOpen(true);
          }
        }
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [cart, selectedCartIndex, tenderOpen, receiptOpen, whatsAppOpen, shortcutsOpen]);

  const showNotification = (msg: string) => {
    setScanToast(msg);
    setTimeout(() => setScanToast(null), 2500);
  };

  // Math Calculations (Strict integer paise invariants)
  const subtotalPaise = cart.reduce((acc, item) => acc + item.unitPricePaise * item.quantity, 0);
  const mrpTotalPaise = cart.reduce((acc, item) => acc + item.mrpPaise * item.quantity, 0);
  const totalSavingsPaise = Math.max(0, mrpTotalPaise - subtotalPaise);

  // Compute Tax
  const totalTaxPaise = cart.reduce((acc, item) => {
    if (item.taxRate <= 0) return acc;
    const itemTotal = item.unitPricePaise * item.quantity;
    const tax = Math.round((itemTotal * item.taxRate) / (100 + item.taxRate));
    return acc + tax;
  }, 0);

  const cgstPaise = Math.round(totalTaxPaise / 2);
  const sgstPaise = totalTaxPaise - cgstPaise;

  // Round-off calculation to nearest ₹1 (100 paise)
  const rawTotal = subtotalPaise;
  const roundedRupees = Math.round(rawTotal / 100);
  const finalGrandTotalPaise = roundedRupees * 100;
  const roundOffPaise = finalGrandTotalPaise - rawTotal;

  // Cart Operations
  const addToCart = (product: WebProduct, qty = 1) => {
    setCart((prev) => {
      const existing = prev.find((item) => item.productId === product.id);
      if (existing) {
        return prev.map((item) =>
          item.productId === product.id
            ? { ...item, quantity: parseFloat((item.quantity + qty).toFixed(2)) }
            : item
        );
      } else {
        const newItem: WebCartItem = {
          id: `cart-${Date.now()}-${product.id}`,
          productId: product.id,
          name: product.name,
          unit: product.unit,
          quantity: qty,
          unitPricePaise: product.sellingPricePaise,
          mrpPaise: product.mrpPaise,
          discountPaise: 0,
          taxRate: product.taxRate,
          hsnCode: product.hsnCode,
          barcode: product.barcode,
          isLoose: product.unit === "kg",
        };
        return [...prev, newItem];
      }
    });

    posAudio.beepSuccess();
    showNotification(`Added: ${product.name}`);
  };

  const updateQuantity = (cartItemId: string, delta: number) => {
    setCart((prev) =>
      prev
        .map((item) => {
          if (item.id === cartItemId) {
            const nextQty = item.isLoose
              ? parseFloat((item.quantity + delta * 0.25).toFixed(2))
              : item.quantity + delta;
            return nextQty > 0 ? { ...item, quantity: nextQty } : null;
          }
          return item;
        })
        .filter(Boolean) as WebCartItem[]
    );
    posAudio.beepSuccess();
  };

  const removeItem = (cartItemId: string) => {
    setCart((prev) => prev.filter((item) => item.id !== cartItemId));
    posAudio.beepError();
  };

  const clearCart = () => {
    if (cart.length === 0) return;
    setCart([]);
    posAudio.beepError();
    showNotification("Cart cleared");
  };

  // Barcode / Fast Search Enter Handling
  const handleSearchKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter" && searchQuery.trim()) {
      e.preventDefault();
      const q = searchQuery.trim().toLowerCase();

      // 1. Direct barcode / SKU match
      const exactMatch = INVENTORY_ITEMS.find(
        (p: WebProduct) => p.barcode === searchQuery.trim() || p.id.toLowerCase() === q
      );

      if (exactMatch) {
        addToCart(exactMatch, 1);
        setSearchQuery("");
        return;
      }

      // 2. Exact or single filtered match
      const matches = INVENTORY_ITEMS.filter(
        (p: WebProduct) =>
          p.name.toLowerCase().includes(q) ||
          p.categoryName.toLowerCase().includes(q) ||
          p.barcode?.includes(q)
      );

      if (matches.length > 0) {
        addToCart(matches[0], 1);
        setSearchQuery("");
      } else {
        posAudio.beepError();
        showNotification(`No item matching: "${searchQuery}"`);
      }
    } else if (e.key === "ArrowDown") {
      e.preventDefault();
      searchInputRef.current?.blur();
      setSelectedCartIndex(0);
    } else if (e.key === "Escape") {
      e.preventDefault();
      setSearchQuery("");
      searchInputRef.current?.blur();
    }
  };

  // Hold / Recall Bills
  const handleHoldBill = () => {
    if (cart.length === 0) {
      posAudio.beepError();
      showNotification("Cart is empty, nothing to hold.");
      return;
    }

    const heldBill: WebHeldBill = {
      id: `HOLD-${Date.now().toString().slice(-4)}`,
      parkedAt: new Date().toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" }),
      customerName: selectedCustomer.name,
      customerPhone: selectedCustomer.phone,
      items: [...cart],
      subtotalPaise: finalGrandTotalPaise,
    };

    setHeldBills((prev) => [heldBill, ...prev]);
    setCart([]);
    posAudio.cashRegisterChime();
    showNotification(`Bill held (#${heldBill.id})`);
  };

  const recallBill = (held: WebHeldBill) => {
    if (cart.length > 0) {
      // Park current first
      handleHoldBill();
    }
    setCart(held.items);
    const cust = customersList.find((c) => c.phone === held.customerPhone) || customersList[0];
    setSelectedCustomer(cust);
    setHeldBills((prev) => prev.filter((b) => b.id !== held.id));
    posAudio.beepSuccess();
    showNotification(`Recalled held bill #${held.id}`);
  };

  // Tender Completion
  const handleTenderComplete = (mode: "CASH" | "UPI" | "UDHAAR") => {
    posAudio.cashRegisterChime();

    const invId = `INV-2026-${String(billSequence).padStart(4, "0")}`;
    const invoicePayload = {
      invoiceNumber: invId,
      dateStr: new Date().toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" }),
      customerName: selectedCustomer.name,
      customerPhone: selectedCustomer.phone !== "9999999999" ? selectedCustomer.phone : undefined,
      paymentMode: mode === "CASH" ? "Cash" : mode === "UPI" ? "UPI QR" : "Udhaar (Khata)",
      totalPaise: finalGrandTotalPaise,
      subtotalPaise: subtotalPaise,
      gstPaise: totalTaxPaise,
      cashierName: "Ramesh Kumar",
      items: cart.map((i) => ({
        name: i.name,
        qty: i.quantity,
        ratePaise: i.unitPricePaise,
        totalPaise: Math.round(i.quantity * i.unitPricePaise),
        hsn: i.hsnCode,
      })),
    };

    setCompletedInvoice(invoicePayload);
    setBillSequence((prev) => prev + 1);
    setTenderOpen(false);
    setReceiptOpen(true);
    setCart([]);
  };

  // Quick Customer Registration Handler (Phase 19.3)
  const handleCustomerCreated = (newCust: NewCustomerData) => {
    const formatted: WebCustomer = {
      id: newCust.id,
      name: newCust.name,
      phone: newCust.phone,
      creditLimitPaise: newCust.creditLimitPaise,
      currentBalancePaise: newCust.currentBalancePaise,
      loyaltyPoints: newCust.loyaltyPoints,
    };
    setCustomersList((prev) => [formatted, ...prev]);
    setSelectedCustomer(formatted);
    showNotification(`Customer linked: ${formatted.name} (+91 ${formatted.phone})`);
  };

  // Filter Catalog
  const filteredProducts = INVENTORY_ITEMS.filter((product) => {
    const matchesCategory =
      selectedCategory === "All" || product.categoryName === selectedCategory;
    const matchesQuery =
      !searchQuery.trim() ||
      product.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      product.barcode?.includes(searchQuery) ||
      product.categoryName.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCategory && matchesQuery;
  });

  const formatRupees = (paise: number) =>
    `₹${(paise / 100).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

  return (
    <div className="flex h-screen bg-slate-950 text-slate-100 overflow-hidden font-sans select-none">
      {/* Modals */}
      <QuickTenderModal
        isOpen={tenderOpen}
        onClose={() => setTenderOpen(false)}
        defaultBillAmount={finalGrandTotalPaise / 100}
        onTenderSuccess={handleTenderComplete}
      />
      <ThermalReceiptModal
        isOpen={receiptOpen}
        onClose={() => setReceiptOpen(false)}
        invoiceData={completedInvoice || undefined}
      />
      <WhatsAppInvoiceModal
        isOpen={whatsAppOpen}
        onClose={() => setWhatsAppOpen(false)}
        invoice={completedInvoice ? {
          invoiceNumber: completedInvoice.invoiceNumber,
          customerName: completedInvoice.customerName,
          dateStr: completedInvoice.dateStr,
          totalPaise: completedInvoice.totalPaise,
          paymentMode: completedInvoice.paymentMode,
        } : null}
      />
      <KeyboardShortcutsModal
        isOpen={shortcutsOpen}
        onClose={() => setShortcutsOpen(false)}
      />
      <QuickCustomerModal
        isOpen={customerModalOpen}
        onClose={() => setCustomerModalOpen(false)}
        onCustomerCreated={handleCustomerCreated}
        existingPhones={customersList.map((c) => c.phone)}
      />

      {/* Sidebar for Navigation */}
      <Sidebar isOpen={mobileNavOpen} onClose={() => setMobileNavOpen(false)} />

      {/* Main POS Interface Area */}
      <div className="flex-1 flex flex-col min-w-0 h-full overflow-hidden bg-slate-900">
        {/* Top Counter Bar */}
        <header className="h-14 border-b border-slate-800 bg-slate-950/90 px-4 sm:px-6 flex items-center justify-between shrink-0 z-20">
          <div className="flex items-center gap-3">
            <button
              onClick={() => setMobileNavOpen(true)}
              className="lg:hidden p-1.5 text-slate-400 hover:text-white rounded-lg hover:bg-slate-800"
            >
              <ShoppingCart className="w-5 h-5 text-emerald-400" />
            </button>
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse"></span>
              <h1 className="font-extrabold text-white text-sm sm:text-base tracking-tight flex items-center gap-2">
                <span>KiranaOS Terminal</span>
                <span className="text-[11px] font-mono px-2 py-0.5 rounded bg-emerald-950 text-emerald-300 border border-emerald-800/80">
                  REG #01
                </span>
              </h1>
            </div>
            <div className="hidden md:flex items-center gap-2 text-xs text-slate-400 pl-2 border-l border-slate-800">
              <Clock className="w-3.5 h-3.5 text-slate-500" />
              <span className="font-mono text-slate-300">{currentTime || "Live"}</span>
            </div>
          </div>

          <div className="flex items-center gap-2 sm:gap-3">
            {/* Held Bills Badge / Recall */}
            {heldBills.length > 0 && (
              <div className="relative group">
                <button
                  type="button"
                  className="flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-amber-500/10 text-amber-300 border border-amber-500/30 text-xs font-bold hover:bg-amber-500/20 transition-colors"
                >
                  <PauseCircle className="w-3.5 h-3.5" />
                  <span>Held ({heldBills.length})</span>
                </button>
                {/* Dropdown to recall */}
                <div className="absolute right-0 mt-1 w-64 p-2 bg-slate-900 border border-slate-700 rounded-xl shadow-2xl opacity-0 pointer-events-none group-hover:opacity-100 group-hover:pointer-events-auto transition-all z-50">
                  <p className="text-[11px] font-bold text-slate-400 uppercase tracking-wider px-2 py-1">
                    Parked Invoices
                  </p>
                  <div className="space-y-1">
                    {heldBills.map((b) => (
                      <button
                        key={b.id}
                        onClick={() => recallBill(b)}
                        className="w-full text-left p-2 rounded-lg hover:bg-slate-800 flex items-center justify-between text-xs text-slate-200 transition-colors"
                      >
                        <div>
                          <p className="font-bold">{b.customerName}</p>
                          <p className="text-[10px] text-slate-400">{b.parkedAt} • {b.items.length} items</p>
                        </div>
                        <span className="font-mono font-bold text-emerald-400">
                          {formatRupees(b.subtotalPaise)}
                        </span>
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            )}

            {/* Keyboard Shortcuts Trigger */}
            <button
              onClick={() => setShortcutsOpen(true)}
              className="flex items-center gap-1.5 px-2.5 py-1 text-xs text-slate-400 hover:text-white bg-slate-800/80 hover:bg-slate-800 border border-slate-700 rounded-lg transition-colors cursor-pointer"
              title="View Keyboard Shortcuts"
            >
              <Keyboard className="w-3.5 h-3.5 text-teal-400" />
              <span className="hidden sm:inline">Keys</span>
              <kbd className="px-1 text-[10px] font-mono bg-slate-900 text-slate-400 rounded">?</kbd>
            </button>

            {/* Cashier Badge */}
            <div className="hidden sm:flex items-center gap-2 px-2.5 py-1 bg-slate-800/50 rounded-lg border border-slate-800 text-xs">
              <span className="w-2 h-2 rounded-full bg-emerald-400"></span>
              <span className="text-slate-300 font-medium">Ramesh (Owner)</span>
            </div>
          </div>
        </header>

        {/* Scan / Alert Feedback Notification Toast */}
        <AnimatePresence>
          {scanToast && (
            <motion.div
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              className="absolute top-16 left-1/2 -translate-x-1/2 z-50 px-4 py-2 bg-emerald-600 text-white text-xs font-bold rounded-xl shadow-xl shadow-emerald-950/50 flex items-center gap-2 border border-emerald-400"
            >
              <CheckCircle2 className="w-4 h-4 text-emerald-100" />
              <span>{scanToast}</span>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Dual-Pane Counter Layout */}
        <div className="flex-1 flex flex-col lg:flex-row overflow-hidden">
          {/* LEFT PANE: Catalog Explorer & Fast Quick-Add */}
          <div className="flex-1 flex flex-col border-r border-slate-800 min-w-0 overflow-hidden bg-slate-900/60">
            {/* Search, Barcode Input & Voice Action Bar */}
            <div className="p-3 sm:p-4 border-b border-slate-800 bg-slate-900 flex items-center gap-2.5 shrink-0">
              <div className="relative flex-1">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                  <Barcode className="h-5 w-5 text-emerald-400" />
                </div>
                <input
                  ref={searchInputRef}
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onKeyDown={handleSearchKeyDown}
                  placeholder="Scan barcode or type item name (Press Enter to add)... [F2]"
                  className="w-full pl-11 pr-24 py-2.5 bg-slate-950 border border-slate-700/80 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500 font-medium transition-all shadow-inner"
                  autoFocus
                />
                <div className="absolute inset-y-0 right-0 pr-2 flex items-center gap-1">
                  {searchQuery && (
                    <button
                      type="button"
                      onClick={() => setSearchQuery("")}
                      className="p-1 text-slate-400 hover:text-white rounded"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  )}
                  <kbd className="hidden sm:inline px-1.5 py-0.5 text-[10px] font-mono font-bold bg-slate-800 text-slate-400 rounded border border-slate-700">
                    F2
                  </kbd>
                </div>
              </div>

              {/* Voice Command Button */}
              <VoiceSearchButton
                onResult={(text: string) => {
                  setSearchQuery(text);
                  posAudio.beepSuccess();
                }}
              />
            </div>

            {/* Category Filter Pills */}
            <div className="px-3 sm:px-4 py-2 border-b border-slate-800/80 bg-slate-950/40 flex items-center gap-1.5 overflow-x-auto no-scrollbar shrink-0">
              {CATEGORIES.map((cat) => {
                const isSelected = selectedCategory === cat;
                return (
                  <button
                    key={cat}
                    onClick={() => setSelectedCategory(cat)}
                    className={`px-3 py-1 rounded-lg text-xs font-bold whitespace-nowrap transition-all cursor-pointer ${
                      isSelected
                        ? "bg-emerald-600 text-white shadow-sm shadow-emerald-900/40"
                        : "bg-slate-800/70 text-slate-300 hover:bg-slate-800 hover:text-white"
                    }`}
                  >
                    {cat}
                  </button>
                );
              })}
            </div>

            {/* Product Grid Area */}
            <div className="flex-1 overflow-y-auto p-3 sm:p-4 grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-4 gap-2.5 sm:gap-3 content-start">
              {filteredProducts.map((product) => {
                const cartItem = cart.find((i) => i.productId === product.id);
                const isLowStock = product.currentStock <= product.minStockThreshold;

                return (
                  <motion.div
                    key={product.id}
                    whileHover={{ y: -2 }}
                    whileTap={{ scale: 0.98 }}
                    onClick={() => addToCart(product, 1)}
                    className={`p-3 rounded-xl border flex flex-col justify-between cursor-pointer transition-all ${
                      cartItem
                        ? "bg-emerald-950/30 border-emerald-700/80 shadow-md shadow-emerald-950/30"
                        : "bg-slate-800/60 hover:bg-slate-800 border-slate-700/70 hover:border-slate-600"
                    }`}
                  >
                    <div>
                      <div className="flex items-start justify-between gap-1.5 mb-1.5">
                        <span className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider truncate">
                          {product.categoryName}
                        </span>
                        {isLowStock && (
                          <span className="text-[9px] font-black uppercase px-1.5 py-0.2 rounded bg-amber-500/20 text-amber-300 border border-amber-500/40 shrink-0">
                            Low: {product.currentStock}
                          </span>
                        )}
                      </div>
                      <h4 className="text-xs sm:text-sm font-bold text-white line-clamp-2 leading-tight">
                        {product.name}
                      </h4>
                    </div>

                    <div className="mt-3 pt-2 border-t border-slate-700/50 flex items-end justify-between">
                      <div>
                        <div className="flex items-baseline gap-1.5">
                          <span className="text-sm sm:text-base font-extrabold text-emerald-400 font-mono">
                            {formatRupees(product.sellingPricePaise)}
                          </span>
                          {product.mrpPaise > product.sellingPricePaise && (
                            <span className="text-[11px] text-slate-500 line-through font-mono">
                              {formatRupees(product.mrpPaise)}
                            </span>
                          )}
                        </div>
                        <span className="text-[10px] text-slate-400 font-medium">
                          per {product.unit}
                        </span>
                      </div>

                      {cartItem ? (
                        <span className="w-6 h-6 rounded-lg bg-emerald-500 text-slate-950 text-xs font-black flex items-center justify-center shadow-sm">
                          {cartItem.quantity}
                        </span>
                      ) : (
                        <span className="w-6 h-6 rounded-lg bg-slate-700 text-slate-300 group-hover:bg-emerald-600 group-hover:text-white flex items-center justify-center transition-colors">
                          <Plus className="w-3.5 h-3.5" />
                        </span>
                      )}
                    </div>
                  </motion.div>
                );
              })}
            </div>
          </div>

          {/* RIGHT PANE: Live Cart Ledger & Checkout Panel */}
          <div className="w-full lg:w-[420px] xl:w-[460px] flex flex-col bg-slate-950 shrink-0 border-t lg:border-t-0 border-slate-800">
            {/* Customer & Bill Identifier Header */}
            <div className="p-3 sm:p-4 border-b border-slate-800 bg-slate-900/80 flex items-center justify-between gap-3 shrink-0">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-xs font-mono font-bold text-emerald-400">
                    #INV-2026-{String(billSequence).padStart(4, "0")}
                  </span>
                  <span className="text-[10px] text-slate-500">•</span>
                  <span className="text-xs text-slate-400">{cart.length} line items</span>
                </div>
                {/* Customer Dropdown & Quick Add (Phase 19.3) */}
                <div className="flex items-center gap-1.5">
                  <div className="relative flex-1">
                    <select
                      value={selectedCustomer.id}
                      onChange={(e) => {
                        const found = customersList.find((c) => c.id === e.target.value);
                        if (found) setSelectedCustomer(found);
                      }}
                      className="w-full py-1.5 pl-2 pr-7 bg-slate-800 border border-slate-700 rounded-lg text-xs font-semibold text-white focus:outline-none focus:ring-1 focus:ring-emerald-500 cursor-pointer appearance-none truncate"
                    >
                      {customersList.map((c) => (
                        <option key={c.id} value={c.id}>
                          {c.name} {c.phone !== "9999999999" ? `(${c.phone})` : ""}
                        </option>
                      ))}
                    </select>
                    <ChevronDown className="w-3.5 h-3.5 text-slate-400 absolute right-2 top-1/2 -translate-y-1/2 pointer-events-none" />
                  </div>

                  <button
                    type="button"
                    onClick={() => setCustomerModalOpen(true)}
                    className="py-1.5 px-2.5 rounded-lg bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-300 border border-emerald-500/40 text-xs font-bold transition-all cursor-pointer flex items-center gap-1 shrink-0"
                    title="Register new customer account (F3)"
                  >
                    <UserPlus className="w-3.5 h-3.5" />
                    <span>+ Add</span>
                    <kbd className="hidden sm:inline text-[9px] font-mono bg-emerald-950 px-1 rounded text-emerald-200">
                      F3
                    </kbd>
                  </button>
                </div>
              </div>

              {/* Customer Khata & Loyalty Status Pill */}
              {selectedCustomer.id !== "c-walkin" && (
                <div className="text-right shrink-0">
                  <div className="text-[10px] font-bold text-slate-400 uppercase">Khata Balance</div>
                  <div
                    className={`text-xs font-mono font-black ${
                      selectedCustomer.currentBalancePaise > 0 ? "text-amber-400" : "text-emerald-400"
                    }`}
                  >
                    {formatRupees(selectedCustomer.currentBalancePaise)}
                  </div>
                  <div className="text-[10px] text-teal-400 font-semibold flex items-center justify-end gap-1">
                    <Sparkles className="w-2.5 h-2.5" />
                    <span>{selectedCustomer.loyaltyPoints} pts</span>
                  </div>
                </div>
              )}
            </div>

            {/* Cart Items List */}
            <div className="flex-1 overflow-y-auto p-3 sm:p-4 space-y-2">
              {cart.length === 0 ? (
                <div className="h-full flex flex-col items-center justify-center text-center p-6 text-slate-500">
                  <ShoppingCart className="w-12 h-12 text-slate-700 mb-3 stroke-[1.5]" />
                  <h3 className="text-sm font-bold text-slate-400">Cart is Empty</h3>
                  <p className="text-xs text-slate-500 mt-1 max-w-[200px]">
                    Scan a barcode or click catalog items to start billing.
                  </p>
                </div>
              ) : (
                cart.map((item, index) => {
                  const isSelected = index === selectedCartIndex;
                  return (
                    <motion.div
                      key={item.id}
                      layout
                      initial={{ opacity: 0, y: 5 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, scale: 0.95 }}
                      onClick={() => setSelectedCartIndex(index)}
                      className={`p-3 rounded-xl border transition-all cursor-pointer shadow-xs ${
                        isSelected
                          ? "bg-slate-800/95 border-emerald-500/80 ring-1 ring-emerald-500/40"
                          : "bg-slate-900/90 border-slate-800 hover:border-slate-700"
                      }`}
                    >
                      <div className="flex items-center justify-between gap-3">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <h4 className="text-xs font-bold text-white truncate leading-tight">
                              {item.name}
                            </h4>
                            {isSelected && (
                              <span className="px-1.5 py-0.2 rounded text-[9px] font-mono font-bold bg-emerald-950 text-emerald-300 border border-emerald-500/40 shrink-0">
                                Active (+/-)
                              </span>
                            )}
                          </div>
                          <div className="flex items-center gap-2 mt-1 text-[11px] text-slate-400">
                            <span className="font-mono text-slate-300">
                              {formatRupees(item.unitPricePaise)}
                            </span>
                            <span>×</span>
                            <span className="font-semibold text-emerald-400">
                              {item.quantity} {item.unit}
                            </span>
                            {item.taxRate > 0 && (
                              <span className="text-[9px] px-1 bg-slate-800 text-slate-400 rounded">
                                GST {item.taxRate}%
                              </span>
                            )}
                          </div>
                        </div>

                        {/* Quantity Stepper & Remove Button */}
                        <div className="flex items-center gap-1.5 shrink-0" onClick={(e) => e.stopPropagation()}>
                          <div className="flex items-center bg-slate-950 border border-slate-800 rounded-lg overflow-hidden">
                            <button
                              type="button"
                              onClick={() => updateQuantity(item.id, -1)}
                              className="p-1 hover:bg-slate-800 text-slate-400 hover:text-white transition-colors"
                              title="Decrease quantity (- on NumPad)"
                            >
                              <Minus className="w-3.5 h-3.5" />
                            </button>
                            <span className="w-8 text-center text-xs font-mono font-bold text-white">
                              {item.quantity}
                            </span>
                            <button
                              type="button"
                              onClick={() => updateQuantity(item.id, 1)}
                              className="p-1 hover:bg-slate-800 text-slate-400 hover:text-white transition-colors"
                              title="Increase quantity (+ on NumPad)"
                            >
                              <Plus className="w-3.5 h-3.5" />
                            </button>
                          </div>

                          <span className="w-16 text-right font-mono font-bold text-xs text-white">
                            {formatRupees(Math.round(item.unitPricePaise * item.quantity))}
                          </span>

                          <button
                            type="button"
                            onClick={() => removeItem(item.id)}
                            className="p-1 text-slate-500 hover:text-rose-400 rounded transition-colors"
                            title="Remove item (Delete)"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </div>

                      {/* Loose Item Fast Weight Increment Chips (Phase 19.2) */}
                      {item.isLoose && (
                        <div className="mt-2 pt-2 border-t border-slate-800/80 flex items-center justify-between text-[10px]">
                          <span className="text-slate-400 font-semibold">Quick Weight:</span>
                          <div className="flex items-center gap-1">
                            {[0.25, 0.5, 1, 2, 5].map((w) => (
                              <button
                                key={w}
                                type="button"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  setCart((prev) =>
                                    prev.map((it) => (it.id === item.id ? { ...it, quantity: w } : it))
                                  );
                                  posAudio.beepSuccess();
                                }}
                                className={`px-1.5 py-0.5 rounded border transition-colors cursor-pointer ${
                                  item.quantity === w
                                    ? "bg-emerald-600 text-white border-emerald-400 font-bold"
                                    : "bg-slate-950 text-slate-300 border-slate-700 hover:border-slate-500"
                                }`}
                              >
                                {w >= 1 ? `${w}kg` : `${w * 1000}g`}
                              </button>
                            ))}
                          </div>
                        </div>
                      )}
                    </motion.div>
                  );
                })
              )}
            </div>

            {/* Bill Summary & Breakdown */}
            <div className="p-3 sm:p-4 border-t border-slate-800 bg-slate-950/80 space-y-2 shrink-0">
              <div className="flex items-center justify-between text-xs text-slate-400">
                <span>Subtotal ({cart.length} items)</span>
                <span className="font-mono text-slate-200">{formatRupees(subtotalPaise)}</span>
              </div>

              {totalSavingsPaise > 0 && (
                <div className="flex items-center justify-between text-xs text-emerald-400 font-medium">
                  <span>Customer MRP Savings</span>
                  <span className="font-mono">- {formatRupees(totalSavingsPaise)}</span>
                </div>
              )}

              {totalTaxPaise > 0 && (
                <div className="flex items-center justify-between text-xs text-slate-400">
                  <span>GST Breakup (CGST + SGST)</span>
                  <span className="font-mono text-slate-300">{formatRupees(totalTaxPaise)}</span>
                </div>
              )}

              {roundOffPaise !== 0 && (
                <div className="flex items-center justify-between text-xs text-slate-500">
                  <span>Round-off adjustment</span>
                  <span className="font-mono">
                    {roundOffPaise > 0 ? `+${formatRupees(roundOffPaise)}` : formatRupees(roundOffPaise)}
                  </span>
                </div>
              )}

              {/* Grand Total Strip */}
              <div className="pt-2 border-t border-slate-800 flex items-baseline justify-between">
                <div>
                  <span className="text-xs uppercase font-extrabold tracking-wider text-slate-400">
                    Grand Total
                  </span>
                  <div className="text-[10px] text-slate-500">Includes all taxes</div>
                </div>
                <div className="text-2xl sm:text-3xl font-black font-mono text-emerald-400 tracking-tight">
                  {formatRupees(finalGrandTotalPaise)}
                </div>
              </div>

              {/* Counter Action Buttons */}
              <div className="pt-2 grid grid-cols-3 gap-2">
                <button
                  type="button"
                  onClick={clearCart}
                  disabled={cart.length === 0}
                  className="py-2.5 px-3 rounded-xl bg-slate-900 hover:bg-slate-800 text-slate-300 hover:text-white border border-slate-700 text-xs font-bold transition-all disabled:opacity-40 cursor-pointer flex items-center justify-center gap-1.5"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                  <span>Clear</span>
                </button>

                <button
                  type="button"
                  onClick={handleHoldBill}
                  disabled={cart.length === 0}
                  className="py-2.5 px-3 rounded-xl bg-amber-500/10 hover:bg-amber-500/20 text-amber-300 border border-amber-500/30 text-xs font-bold transition-all disabled:opacity-40 cursor-pointer flex items-center justify-center gap-1.5"
                >
                  <PauseCircle className="w-3.5 h-3.5" />
                  <span>Hold</span>
                  <kbd className="hidden sm:inline text-[9px] font-mono bg-amber-950 text-amber-200 px-1 rounded">
                    F9
                  </kbd>
                </button>

                <button
                  type="button"
                  onClick={() => {
                    if (cart.length > 0) {
                      posAudio.beepSuccess();
                      setTenderOpen(true);
                    }
                  }}
                  disabled={cart.length === 0}
                  className="py-2.5 px-3 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white font-extrabold text-xs shadow-lg shadow-emerald-950/60 transition-all disabled:opacity-40 cursor-pointer flex items-center justify-center gap-1.5"
                >
                  <Banknote className="w-4 h-4" />
                  <span>Tender</span>
                  <kbd className="text-[9px] font-mono bg-white/20 text-white px-1 rounded">
                    F4
                  </kbd>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
