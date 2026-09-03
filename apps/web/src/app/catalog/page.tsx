"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Sidebar } from "@/components/layout/Sidebar";
import { Header } from "@/components/layout/Header";
import {
  Package,
  Search,
  Plus,
  Filter,
  Barcode,
  ArrowUpDown,
  AlertTriangle,
  CheckCircle2,
  XCircle,
  Tag,
  Edit2,
  Sparkles,
  Download,
  X,
  Printer,
  Boxes,
  Percent,
  PlusCircle,
  MinusCircle,
  ArrowRight,
  TrendingUp,
  FileSpreadsheet,
} from "lucide-react";
import { WebProduct } from "@/types";
import { posAudio } from "@/utils/audioFeedback";
import { BarcodeLabelStudioModal } from "@/components/catalog/BarcodeLabelStudioModal";
import { BulkProductImportModal } from "@/components/catalog/BulkProductImportModal";

const INITIAL_PRODUCTS: WebProduct[] = [
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
    barcode: "8906007280143",
    isActive: true,
  },
  {
    id: "p3",
    name: "Tata Salt Vacuum Evaporated 1kg",
    categoryName: "Spices, Salt & Sugar",
    unit: "packet",
    sellingPricePaise: 2800,
    mrpPaise: 3000,
    costPricePaise: 2400,
    taxRate: 0.0,
    currentStock: 120,
    minStockThreshold: 25,
    hsnCode: "2501",
    barcode: "8901030010040",
    isActive: true,
  },
  {
    id: "p4",
    name: "Amul Pasteurised Butter 500g",
    categoryName: "Dairy & Fresh",
    unit: "packet",
    sellingPricePaise: 27500,
    mrpPaise: 28500,
    costPricePaise: 25000,
    taxRate: 12.0,
    currentStock: 7,
    minStockThreshold: 8,
    hsnCode: "0405",
    barcode: "8901262010054",
    isActive: true,
  },
  {
    id: "p5",
    name: "Nestle Maggi 2-Minute Masala Noodles 70g",
    categoryName: "Snacks & Biscuits",
    unit: "packet",
    sellingPricePaise: 1400,
    mrpPaise: 1400,
    costPricePaise: 1180,
    taxRate: 12.0,
    currentStock: 200,
    minStockThreshold: 40,
    hsnCode: "1902",
    barcode: "8901058852370",
    isActive: true,
  },
  {
    id: "p6",
    name: "Parle-G Gold Glucose Biscuits 100g",
    categoryName: "Snacks & Biscuits",
    unit: "packet",
    sellingPricePaise: 1000,
    mrpPaise: 1000,
    costPricePaise: 850,
    taxRate: 18.0,
    currentStock: 150,
    minStockThreshold: 30,
    hsnCode: "1905",
    barcode: "8901719101038",
    isActive: true,
  },
  {
    id: "p7",
    name: "Brooke Bond Red Label Tea 500g",
    categoryName: "Tea, Coffee & Drinks",
    unit: "packet",
    sellingPricePaise: 29000,
    mrpPaise: 31000,
    costPricePaise: 26000,
    taxRate: 5.0,
    currentStock: 3,
    minStockThreshold: 10,
    hsnCode: "0902",
    barcode: "8901030383120",
    isActive: true,
  },
  {
    id: "p8",
    name: "Surf Excel Quick Wash Detergent Powder 1kg",
    categoryName: "Household & Cleaning",
    unit: "packet",
    sellingPricePaise: 16000,
    mrpPaise: 17500,
    costPricePaise: 13800,
    taxRate: 18.0,
    currentStock: 50,
    minStockThreshold: 12,
    hsnCode: "3402",
    barcode: "8901030886547",
    isActive: true,
  },
];

export default function ProductCatalogPage() {
  const [products, setProducts] = useState<WebProduct[]>(INITIAL_PRODUCTS);
  const [search, setSearch] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("All");
  const [filterStockStatus, setFilterStockStatus] = useState("All");

  // Modals state
  const [showAddModal, setShowAddModal] = useState(false);
  const [showBarcodeStudio, setShowBarcodeStudio] = useState(false);
  const [showBulkImportModal, setShowBulkImportModal] = useState(false);
  const [studioProduct, setStudioProduct] = useState<WebProduct | null>(null);
  const [adjustingProduct, setAdjustingProduct] = useState<WebProduct | null>(null);
  const [tagProduct, setTagProduct] = useState<WebProduct | null>(null);
  const [editingProduct, setEditingProduct] = useState<WebProduct | null>(null);
  const [mobileNavOpen, setMobileNavOpen] = useState(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // New Product Form State
  const [newProdName, setNewProdName] = useState("");
  const [newProdCat, setNewProdCat] = useState("Atta & Flours");
  const [newProdUnit, setNewProdUnit] = useState("packet");
  const [newProdMRP, setNewProdMRP] = useState("100.00");
  const [newProdSell, setNewProdSell] = useState("95.00");
  const [newProdCost, setNewProdCost] = useState("80.00");
  const [newProdTax, setNewProdTax] = useState("5.0");
  const [newProdStock, setNewProdStock] = useState("50");
  const [newProdMin, setNewProdMin] = useState("10");
  const [newProdBarcode, setNewProdBarcode] = useState("");

  // Stock Adjust form
  const [stockDelta, setStockDelta] = useState("10");
  const [adjustType, setAdjustType] = useState<"add" | "sub">("add");
  const [adjustReason, setAdjustReason] = useState("Inward Restock Delivery");

  const categories = [
    "All",
    "Atta & Flours",
    "Edible Oils & Ghee",
    "Spices, Salt & Sugar",
    "Dairy & Fresh",
    "Snacks & Biscuits",
    "Tea, Coffee & Drinks",
    "Household & Cleaning",
  ];

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3000);
  };

  const filteredProducts = products.filter((p) => {
    const matchesSearch =
      p.name.toLowerCase().includes(search.toLowerCase()) ||
      p.barcode?.includes(search) ||
      p.hsnCode?.includes(search);
    const matchesCat = selectedCategory === "All" || p.categoryName === selectedCategory;
    const matchesStock =
      filterStockStatus === "All" ||
      (filterStockStatus === "Low" && p.currentStock <= p.minStockThreshold && p.currentStock > 0) ||
      (filterStockStatus === "Out" && p.currentStock <= 0) ||
      (filterStockStatus === "Healthy" && p.currentStock > p.minStockThreshold);

    return matchesSearch && matchesCat && matchesStock;
  });

  const generateAutoEAN = () => {
    const base12 = "890" + String(Date.now()).slice(-9);
    setNewProdBarcode(base12);
  };

  React.useEffect(() => {
    async function loadCatalog() {
      try {
        const res = await fetch("/api/catalog");
        if (res.ok) {
          const data = await res.json();
          if (data.products && data.products.length > 0) {
            const mapped: WebProduct[] = data.products.map((p: any) => ({
              id: p.id,
              name: p.name,
              categoryName: p.category,
              unit: p.unit || "unit",
              sellingPricePaise: Math.round(p.salePrice * 100),
              mrpPaise: Math.round(p.mrp * 100),
              costPricePaise: Math.round(p.costPrice * 100),
              taxRate: p.gstRate,
              currentStock: p.currentStock,
              minStockThreshold: p.minStock,
              hsnCode: p.hsn,
              barcode: p.barcode,
              isActive: true,
            }));
            setProducts(mapped);
          }
        }
      } catch {
        // Maintain fallback seed products
      }
    }
    loadCatalog();
  }, []);

  const handleQuickStockDelta = (productId: string, delta: number) => {
    setProducts((prev) =>
      prev.map((p) => {
        if (p.id === productId) {
          const newStock = Math.max(0, p.currentStock + delta);
          return { ...p, currentStock: newStock };
        }
        return p;
      })
    );
    posAudio.playBarcodeBeep();
  };

  const handleAddProduct = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newProdName.trim()) return;

    const newProd: WebProduct = {
      id: "p_" + Date.now(),
      name: newProdName.trim(),
      categoryName: newProdCat,
      unit: newProdUnit,
      sellingPricePaise: Math.round(parseFloat(newProdSell || "0") * 100),
      mrpPaise: Math.round(parseFloat(newProdMRP || "0") * 100),
      costPricePaise: Math.round(parseFloat(newProdCost || "0") * 100),
      taxRate: parseFloat(newProdTax || "0"),
      currentStock: parseFloat(newProdStock || "0"),
      minStockThreshold: parseFloat(newProdMin || "10"),
      barcode: newProdBarcode || "890" + String(Date.now()).slice(-9),
      isActive: true,
    };

    setProducts([newProd, ...products]);
    setShowAddModal(false);
    setNewProdName("");
    setNewProdBarcode("");
    posAudio.playSuccessChime();
    showToast(`Added "${newProd.name}" to inventory.`);

    try {
      await fetch("/api/catalog", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: newProd.name,
          category: newProd.categoryName,
          barcode: newProd.barcode,
          salePrice: newProd.sellingPricePaise / 100,
          mrp: newProd.mrpPaise / 100,
          costPrice: newProd.costPricePaise / 100,
          currentStock: newProd.currentStock,
          minStock: newProd.minStockThreshold,
          unit: newProd.unit,
          hsn: "19053100",
          gstRate: newProd.taxRate,
        }),
      });
    } catch {
      // Handled gracefully
    }
  };

  const handleSaveEdit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingProduct) return;

    setProducts(products.map((p) => (p.id === editingProduct.id ? editingProduct : p)));
    setEditingProduct(null);
    showToast(`Updated product "${editingProduct.name}".`);
  };

  const handleStockAdjustment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!adjustingProduct) return;

    const qty = parseInt(stockDelta, 10) || 0;
    const diff = adjustType === "add" ? qty : -qty;
    const newCount = Math.max(0, adjustingProduct.currentStock + diff);

    setProducts(
      products.map((p) =>
        p.id === adjustingProduct.id ? { ...p, currentStock: newCount } : p
      )
    );
    showToast(`Stock updated: ${adjustingProduct.name} is now ${newCount} ${adjustingProduct.unit} (${adjustReason})`);
    setAdjustingProduct(null);
    setStockDelta("10");

    try {
      await fetch("/api/catalog/stock", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          productId: adjustingProduct.id,
          delta: diff,
          reason: adjustReason,
        }),
      });
    } catch {
      // Handled gracefully
    }
  };

  const formatRupees = (paise: number) =>
    `₹${(paise / 100).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

  return (
    <div className="flex min-h-screen bg-slate-50 relative overflow-hidden">
      {/* Aurora Ambient Glows */}
      <div className="absolute top-0 right-0 w-96 h-96 bg-emerald-400/10 rounded-full blur-3xl pointer-events-none"></div>

      <Sidebar isOpen={mobileNavOpen} onClose={() => setMobileNavOpen(false)} />

      <div className="flex-1 flex flex-col min-w-0 z-10">
        <Header
          title="Master Product Catalog"
          subtitle="Manage pricing, barcodes, GST slabs, and safety stock thresholds"
          onMenuClick={() => setMobileNavOpen(true)}
        />

        <main className="p-4 sm:p-6 lg:p-8 space-y-6 flex-1 overflow-auto">
          {/* Notification Toast */}
          <AnimatePresence>
            {toastMessage && (
              <motion.div
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                className="p-3.5 bg-emerald-600 text-white rounded-2xl shadow-lg flex items-center justify-between gap-3 text-xs font-bold"
              >
                <div className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-emerald-200" />
                  <span>{toastMessage}</span>
                </div>
                <button
                  type="button"
                  onClick={() => setToastMessage(null)}
                  className="p-1 hover:bg-emerald-700 rounded-lg cursor-pointer"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Top Bar: Search & Actions */}
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4 glass-card p-4 rounded-2xl shadow-xs">
            <div className="flex items-center gap-3 flex-1">
              <div className="relative flex-1 max-w-md">
                <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Scan barcode or search SKU name..."
                  className="w-full pl-9 pr-4 py-2 bg-slate-100/90 hover:bg-slate-100 focus:bg-white text-xs text-slate-800 rounded-xl border border-slate-200/80 focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/10 focus:outline-none transition-all placeholder:text-slate-400 font-medium"
                />
              </div>

              {/* Stock Filter Pills */}
              <div className="hidden lg:flex items-center gap-1 bg-slate-100/80 p-1 rounded-xl border border-slate-200/60 text-xs font-semibold text-slate-600">
                {["All", "Healthy", "Low", "Out"].map((s) => (
                  <button
                    key={s}
                    onClick={() => setFilterStockStatus(s)}
                    className={`px-2.5 py-1 rounded-lg transition-all cursor-pointer ${
                      filterStockStatus === s ? "bg-white text-slate-900 shadow-xs font-bold" : "hover:text-slate-900"
                    }`}
                  >
                    {s}
                  </button>
                ))}
              </div>
            </div>

            <div className="flex items-center gap-2 sm:gap-3">
              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={() => setShowBulkImportModal(true)}
                className="flex items-center gap-2 px-3.5 py-2 bg-emerald-50 hover:bg-emerald-100 text-emerald-800 border border-emerald-300 rounded-xl text-xs font-bold shadow-xs transition-all cursor-pointer whitespace-nowrap"
              >
                <FileSpreadsheet className="w-4 h-4 text-emerald-600" />
                <span>Bulk CSV Import</span>
              </motion.button>
              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={() => {
                  setStudioProduct(null);
                  setShowBarcodeStudio(true);
                }}
                className="flex items-center gap-2 px-3.5 py-2 bg-slate-900 hover:bg-slate-800 text-slate-100 border border-slate-700/80 rounded-xl text-xs font-bold shadow-xs transition-all cursor-pointer whitespace-nowrap"
              >
                <Barcode className="w-4 h-4 text-emerald-400" />
                <span>Barcode Studio</span>
              </motion.button>
              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={() => setShowAddModal(true)}
                className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 text-white rounded-xl text-xs font-bold shadow-md shadow-emerald-950/20 transition-all cursor-pointer whitespace-nowrap"
              >
                <Plus className="w-4 h-4" />
                <span>Add New SKU</span>
              </motion.button>
            </div>
          </div>

          {/* Category Filter Chips */}
          <div className="flex items-center gap-2 overflow-x-auto pb-1 text-xs font-semibold no-scrollbar">
            {categories.map((cat) => (
              <button
                key={cat}
                onClick={() => setSelectedCategory(cat)}
                className={`px-3.5 py-1.5 rounded-xl transition-all whitespace-nowrap cursor-pointer ${
                  selectedCategory === cat
                    ? "bg-slate-900 text-white shadow-sm font-bold"
                    : "bg-white hover:bg-slate-100 text-slate-600 border border-slate-200/70"
                }`}
              >
                {cat}
              </button>
            ))}
          </div>

          {/* Products Table */}
          <div className="glass-card rounded-2xl shadow-xs overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse">
                <thead>
                  <tr className="bg-slate-100/70 border-b border-slate-200 text-[11px] font-bold text-slate-600 uppercase tracking-wider">
                    <th className="py-3.5 px-4">Product Name & Category</th>
                    <th className="py-3.5 px-4">Barcode & HSN</th>
                    <th className="py-3.5 px-4 text-right">Cost Price</th>
                    <th className="py-3.5 px-4 text-right">Selling Price</th>
                    <th className="py-3.5 px-4 text-right">MRP</th>
                    <th className="py-3.5 px-4 text-center">GST Slab</th>
                    <th className="py-3.5 px-4 text-center">Stock Level</th>
                    <th className="py-3.5 px-4 text-right">Gross Margin</th>
                    <th className="py-3.5 px-4 text-center">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-xs text-slate-700 font-medium">
                  {filteredProducts.map((p) => {
                    const marginPaise = p.sellingPricePaise - p.costPricePaise;
                    const marginPct =
                      p.sellingPricePaise > 0 ? ((marginPaise / p.sellingPricePaise) * 100).toFixed(1) : "0.0";
                    const isLowStock = p.currentStock <= p.minStockThreshold;

                    return (
                      <tr key={p.id} className="hover:bg-slate-50/70 transition-colors">
                        <td className="py-3 px-4">
                          <div className="font-bold text-slate-900">{p.name}</div>
                          <div className="text-[11px] text-slate-400 font-normal">
                            {p.categoryName} • Unit: {p.unit}
                          </div>
                        </td>
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-1.5 font-mono text-[11px] text-slate-800">
                            <Barcode className="w-3.5 h-3.5 text-slate-400" />
                            {p.barcode || "N/A"}
                          </div>
                          {p.hsnCode && (
                            <div className="text-[10px] text-slate-400 font-mono">HSN: {p.hsnCode}</div>
                          )}
                        </td>
                        <td className="py-3 px-4 text-right font-mono text-slate-600">
                          {formatRupees(p.costPricePaise)}
                        </td>
                        <td className="py-3 px-4 text-right font-mono font-bold text-emerald-700">
                          {formatRupees(p.sellingPricePaise)}
                        </td>
                        <td className="py-3 px-4 text-right font-mono text-slate-500">
                          {formatRupees(p.mrpPaise)}
                        </td>
                        <td className="py-3 px-4 text-center">
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 text-slate-700 border border-slate-200">
                            {p.taxRate}% GST
                          </span>
                        </td>
                        <td className="py-3 px-4 text-center">
                          <div className="inline-flex items-center gap-1">
                            <button
                              type="button"
                              onClick={() => handleQuickStockDelta(p.id, -1)}
                              className="w-5 h-5 rounded-md bg-slate-100 hover:bg-rose-100 hover:text-rose-700 text-slate-600 flex items-center justify-center font-bold text-xs transition-colors cursor-pointer"
                              title="Decrease Stock (-1)"
                            >
                              -
                            </button>
                            <button
                              type="button"
                              onClick={() => setAdjustingProduct(p)}
                              className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-bold border cursor-pointer transition-transform hover:scale-105 ${
                                isLowStock
                                  ? "bg-amber-50 text-amber-800 border-amber-200"
                                  : "bg-emerald-50 text-emerald-800 border-emerald-200"
                              }`}
                              title="Click for detailed stock adjustment"
                            >
                              {isLowStock ? (
                                <AlertTriangle className="w-3 h-3 text-amber-600" />
                              ) : (
                                <CheckCircle2 className="w-3 h-3 text-emerald-600" />
                              )}
                              <span>
                                {p.currentStock} {p.unit}
                              </span>
                            </button>
                            <button
                              type="button"
                              onClick={() => handleQuickStockDelta(p.id, 1)}
                              className="w-5 h-5 rounded-md bg-slate-100 hover:bg-emerald-100 hover:text-emerald-700 text-slate-600 flex items-center justify-center font-bold text-xs transition-colors cursor-pointer"
                              title="Increase Stock (+1)"
                            >
                              +
                            </button>
                          </div>
                        </td>
                        <td className="py-3 px-4 text-right font-mono">
                          <span className="font-bold text-slate-900">{formatRupees(marginPaise)}</span>
                          <span className="text-[10px] text-emerald-600 font-semibold block">({marginPct}%)</span>
                        </td>
                        <td className="py-3 px-4 text-center">
                          <div className="flex items-center justify-center gap-1">
                            <button
                              type="button"
                              onClick={() => {
                                setStudioProduct(p);
                                setShowBarcodeStudio(true);
                              }}
                              className="p-1.5 rounded-lg text-slate-500 hover:bg-teal-50 hover:text-teal-700 transition-colors cursor-pointer"
                              title="Print Barcode Stickers"
                            >
                              <Barcode className="w-3.5 h-3.5 text-teal-600" />
                            </button>
                            <button
                              type="button"
                              onClick={() => setTagProduct(p)}
                              className="p-1.5 rounded-lg text-slate-500 hover:bg-emerald-50 hover:text-emerald-700 transition-colors cursor-pointer"
                              title="Print Shelf Tag"
                            >
                              <Tag className="w-3.5 h-3.5" />
                            </button>
                            <button
                              type="button"
                              onClick={() => setEditingProduct(p)}
                              className="p-1.5 rounded-lg text-slate-500 hover:bg-slate-100 hover:text-slate-800 transition-colors cursor-pointer"
                              title="Edit Product"
                            >
                              <Edit2 className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            <div className="p-4 border-t border-slate-100 bg-slate-50/50 flex items-center justify-between text-xs text-slate-500">
              <span>Showing {filteredProducts.length} of {products.length} catalog items</span>
              <span className="font-semibold text-emerald-700">Live Counter Barcode Scanning Active</span>
            </div>
          </div>
        </main>
      </div>

      {/* Modal 1: Add SKU */}
      <AnimatePresence>
        {showAddModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-lg bg-white rounded-3xl p-6 shadow-2xl space-y-4 max-h-[90vh] overflow-y-auto"
            >
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <h3 className="font-bold text-slate-900 text-base flex items-center gap-2">
                  <Package className="w-5 h-5 text-emerald-600" /> Add New Inventory Product SKU
                </h3>
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <form onSubmit={handleAddProduct} className="space-y-4 text-xs">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Product Name & Brand Weight</label>
                  <input
                    type="text"
                    required
                    value={newProdName}
                    onChange={(e) => setNewProdName(e.target.value)}
                    placeholder="e.g. Fortune Besan 500g"
                    className="w-full px-3.5 py-2 rounded-xl bg-slate-50 border border-slate-200 focus:border-emerald-500 focus:bg-white focus:outline-none"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="font-bold text-slate-700 block mb-1">Category</label>
                    <select
                      value={newProdCat}
                      onChange={(e) => setNewProdCat(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 focus:border-emerald-500 focus:bg-white focus:outline-none"
                    >
                      {categories.filter((c) => c !== "All").map((c) => (
                        <option key={c} value={c}>{c}</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="font-bold text-slate-700 block mb-1">Unit of Measure</label>
                    <select
                      value={newProdUnit}
                      onChange={(e) => setNewProdUnit(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 focus:border-emerald-500 focus:bg-white focus:outline-none"
                    >
                      <option value="packet">packet (pkt)</option>
                      <option value="kg">kilogram (kg)</option>
                      <option value="litre">litre (L)</option>
                      <option value="piece">piece (pc)</option>
                    </select>
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-3">
                  <div>
                    <label className="font-bold text-slate-700 block mb-1">Cost Price (₹)</label>
                    <input
                      type="number"
                      step="0.01"
                      required
                      value={newProdCost}
                      onChange={(e) => setNewProdCost(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono"
                    />
                  </div>
                  <div>
                    <label className="font-bold text-slate-700 block mb-1">Selling Price (₹)</label>
                    <input
                      type="number"
                      step="0.01"
                      required
                      value={newProdSell}
                      onChange={(e) => setNewProdSell(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono font-bold text-emerald-700"
                    />
                  </div>
                  <div>
                    <label className="font-bold text-slate-700 block mb-1">MRP (₹)</label>
                    <input
                      type="number"
                      step="0.01"
                      required
                      value={newProdMRP}
                      onChange={(e) => setNewProdMRP(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-3">
                  <div>
                    <label className="font-bold text-slate-700 block mb-1">GST Slab (%)</label>
                    <select
                      value={newProdTax}
                      onChange={(e) => setNewProdTax(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200"
                    >
                      <option value="0.0">0% (Nil)</option>
                      <option value="5.0">5% GST</option>
                      <option value="12.0">12% GST</option>
                      <option value="18.0">18% GST</option>
                      <option value="28.0">28% GST</option>
                    </select>
                  </div>
                  <div>
                    <label className="font-bold text-slate-700 block mb-1">Opening Units</label>
                    <input
                      type="number"
                      value={newProdStock}
                      onChange={(e) => setNewProdStock(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono"
                    />
                  </div>
                  <div>
                    <label className="font-bold text-slate-700 block mb-1">Safety Stock Min</label>
                    <input
                      type="number"
                      value={newProdMin}
                      onChange={(e) => setNewProdMin(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono"
                    />
                  </div>
                </div>

                <div>
                  <div className="flex items-center justify-between mb-1">
                    <label className="font-bold text-slate-700">EAN-13 / UPC Barcode</label>
                    <button
                      type="button"
                      onClick={generateAutoEAN}
                      className="text-[11px] font-bold text-emerald-600 hover:underline cursor-pointer"
                    >
                      Auto-Generate India Barcode
                    </button>
                  </div>
                  <input
                    type="text"
                    value={newProdBarcode}
                    onChange={(e) => setNewProdBarcode(e.target.value)}
                    placeholder="Scan product barcode..."
                    className="w-full px-3.5 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono"
                  />
                </div>

                <div className="pt-3 border-t border-slate-100 flex items-center justify-end gap-3">
                  <button
                    type="button"
                    onClick={() => setShowAddModal(false)}
                    className="px-4 py-2 rounded-xl text-slate-600 hover:bg-slate-100 font-semibold cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="px-5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold shadow-md shadow-emerald-950/20 cursor-pointer"
                  >
                    Save &amp; Add to Catalog
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Modal 2: Stock Adjustment Stepper */}
      <AnimatePresence>
        {adjustingProduct && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-sm bg-white rounded-3xl p-6 shadow-2xl space-y-4"
            >
              <div className="flex items-center justify-between pb-2 border-b border-slate-100">
                <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <Boxes className="w-4 h-4 text-emerald-600" /> Stock Count Adjustment
                </h3>
                <button
                  type="button"
                  onClick={() => setAdjustingProduct(null)}
                  className="text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 text-xs space-y-1">
                <p className="font-bold text-slate-900">{adjustingProduct.name}</p>
                <p className="text-slate-500">
                  Current Stock: <strong className="text-slate-900 font-mono">{adjustingProduct.currentStock}</strong> {adjustingProduct.unit}
                </p>
              </div>

              <form onSubmit={handleStockAdjustment} className="space-y-4 text-xs">
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => setAdjustType("add")}
                    className={`flex-1 py-2 rounded-xl font-bold border cursor-pointer flex items-center justify-center gap-1.5 ${
                      adjustType === "add"
                        ? "bg-emerald-50 text-emerald-800 border-emerald-300"
                        : "bg-slate-50 text-slate-600 border-slate-200"
                    }`}
                  >
                    <PlusCircle className="w-4 h-4 text-emerald-600" />
                    <span>Inward / Restock</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setAdjustType("sub")}
                    className={`flex-1 py-2 rounded-xl font-bold border cursor-pointer flex items-center justify-center gap-1.5 ${
                      adjustType === "sub"
                        ? "bg-rose-50 text-rose-800 border-rose-300"
                        : "bg-slate-50 text-slate-600 border-slate-200"
                    }`}
                  >
                    <MinusCircle className="w-4 h-4 text-rose-600" />
                    <span>Deduct / Damaged</span>
                  </button>
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">Adjustment Quantity Units</label>
                  <input
                    type="number"
                    min="1"
                    required
                    value={stockDelta}
                    onChange={(e) => setStockDelta(e.target.value)}
                    className="w-full px-3.5 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono font-bold text-center text-base"
                  />
                </div>

                <div>
                  <label className="font-bold text-slate-700 block mb-1">Audit Reason</label>
                  <select
                    value={adjustReason}
                    onChange={(e) => setAdjustReason(e.target.value)}
                    className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200"
                  >
                    <option value="Inward Restock Delivery">Inward Restock Delivery</option>
                    <option value="Customer Return">Customer Return</option>
                    <option value="Physical Shelf Count Correction">Physical Shelf Count Correction</option>
                    <option value="Damaged / Expired Goods">Damaged / Expired Goods</option>
                    <option value="Internal Store Consumption">Internal Store Consumption</option>
                  </select>
                </div>

                <div className="pt-2 border-t border-slate-100 flex items-center justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => setAdjustingProduct(null)}
                    className="px-3.5 py-1.5 rounded-xl text-slate-600 hover:bg-slate-100 font-semibold cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold cursor-pointer"
                  >
                    Confirm Adjustment
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Modal 3: Shelf Price Tag Print Preview */}
      <AnimatePresence>
        {tagProduct && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-sm bg-white rounded-3xl p-6 shadow-2xl space-y-4"
            >
              <div className="flex items-center justify-between pb-2 border-b border-slate-100">
                <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <Tag className="w-4 h-4 text-emerald-600" /> Shelf Tag Print Preview (50×25mm)
                </h3>
                <button
                  type="button"
                  onClick={() => setTagProduct(null)}
                  className="text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              {/* Tag Stencil Preview */}
              <div className="p-4 bg-amber-50/50 border-2 border-dashed border-amber-300 rounded-2xl text-slate-900 space-y-2">
                <div className="text-[10px] font-bold text-slate-500 uppercase tracking-wider">
                  Sri Lakshmi Provision &bull; Bengaluru
                </div>
                <div className="font-extrabold text-sm leading-tight">{tagProduct.name}</div>
                <div className="flex items-baseline justify-between pt-1">
                  <div>
                    <span className="text-[10px] text-slate-500 line-through mr-1.5 font-mono">
                      MRP: {formatRupees(tagProduct.mrpPaise)}
                    </span>
                    <span className="text-xl font-black font-mono text-emerald-700">
                      {formatRupees(tagProduct.sellingPricePaise)}
                    </span>
                  </div>
                  {tagProduct.mrpPaise > tagProduct.sellingPricePaise && (
                    <span className="px-2 py-0.5 rounded bg-emerald-600 text-white font-black text-[10px]">
                      SAVE {formatRupees(tagProduct.mrpPaise - tagProduct.sellingPricePaise)}
                    </span>
                  )}
                </div>

                <div className="pt-2 border-t border-slate-300 flex items-center justify-between text-[9px] font-mono text-slate-600">
                  <span className="tracking-widest">||| | || |||| | ||| |||</span>
                  <span>{tagProduct.barcode}</span>
                </div>
              </div>

              <div className="pt-2 flex items-center justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setTagProduct(null)}
                  className="px-3 py-1.5 rounded-xl text-slate-600 hover:bg-slate-100 font-semibold cursor-pointer text-xs"
                >
                  Close
                </button>
                <button
                  type="button"
                  onClick={() => {
                    alert(`Dispatched tag print for "${tagProduct.name}" to thermal roll printer.`);
                    setTagProduct(null);
                  }}
                  className="px-4 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 text-white font-bold cursor-pointer text-xs flex items-center gap-1.5"
                >
                  <Printer className="w-3.5 h-3.5" />
                  <span>Print Shelf Label</span>
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Modal 4: Edit Product */}
      <AnimatePresence>
        {editingProduct && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-md bg-white rounded-3xl p-6 shadow-2xl space-y-4"
            >
              <div className="flex items-center justify-between pb-2 border-b border-slate-100">
                <h3 className="font-bold text-slate-900 text-sm flex items-center gap-2">
                  <Edit2 className="w-4 h-4 text-emerald-600" /> Edit Product Details
                </h3>
                <button
                  type="button"
                  onClick={() => setEditingProduct(null)}
                  className="text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <form onSubmit={handleSaveEdit} className="space-y-3 text-xs">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Product Title</label>
                  <input
                    type="text"
                    required
                    value={editingProduct.name}
                    onChange={(e) => setEditingProduct({ ...editingProduct, name: e.target.value })}
                    className="w-full px-3.5 py-2 rounded-xl bg-slate-50 border border-slate-200"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="font-bold text-slate-700 block mb-1">Selling Price (₹)</label>
                    <input
                      type="number"
                      step="0.01"
                      required
                      value={(editingProduct.sellingPricePaise / 100).toFixed(2)}
                      onChange={(e) =>
                        setEditingProduct({
                          ...editingProduct,
                          sellingPricePaise: Math.round(parseFloat(e.target.value || "0") * 100),
                        })
                      }
                      className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono font-bold text-emerald-700"
                    />
                  </div>
                  <div>
                    <label className="font-bold text-slate-700 block mb-1">MRP (₹)</label>
                    <input
                      type="number"
                      step="0.01"
                      required
                      value={(editingProduct.mrpPaise / 100).toFixed(2)}
                      onChange={(e) =>
                        setEditingProduct({
                          ...editingProduct,
                          mrpPaise: Math.round(parseFloat(e.target.value || "0") * 100),
                        })
                      }
                      className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="font-bold text-slate-700 block mb-1">Cost Price (₹)</label>
                    <input
                      type="number"
                      step="0.01"
                      required
                      value={(editingProduct.costPricePaise / 100).toFixed(2)}
                      onChange={(e) =>
                        setEditingProduct({
                          ...editingProduct,
                          costPricePaise: Math.round(parseFloat(e.target.value || "0") * 100),
                        })
                      }
                      className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono"
                    />
                  </div>
                  <div>
                    <label className="font-bold text-slate-700 block mb-1">Safety Min Stock</label>
                    <input
                      type="number"
                      value={editingProduct.minStockThreshold}
                      onChange={(e) =>
                        setEditingProduct({
                          ...editingProduct,
                          minStockThreshold: parseInt(e.target.value || "0", 10),
                        })
                      }
                      className="w-full px-3 py-2 rounded-xl bg-slate-50 border border-slate-200 font-mono"
                    />
                  </div>
                </div>

                <div className="pt-2 border-t border-slate-100 flex items-center justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => setEditingProduct(null)}
                    className="px-3.5 py-1.5 rounded-xl text-slate-600 hover:bg-slate-100 font-semibold cursor-pointer"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold cursor-pointer"
                  >
                    Save Changes
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Modal 4: Barcode Label Studio & Batch Print */}
      <BarcodeLabelStudioModal
        isOpen={showBarcodeStudio}
        onClose={() => setShowBarcodeStudio(false)}
        products={products}
        selectedProduct={studioProduct}
      />

      {/* Modal 5: Bulk Excel / CSV Importer */}
      <BulkProductImportModal
        isOpen={showBulkImportModal}
        onClose={() => setShowBulkImportModal(false)}
        onImportSuccess={(imported) => {
          setProducts([...imported, ...products]);
          showToast(`Successfully imported ${imported.length} new SKUs to inventory!`);
        }}
      />
    </div>
  );
}
