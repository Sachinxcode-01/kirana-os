"use client";

import React, { useState } from "react";
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
} from "lucide-react";
import { WebProduct } from "@/types";

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
    barcode: "8901030345099",
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
  const [showAddModal, setShowAddModal] = useState(false);

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

  const categories = ["All", "Atta & Flours", "Edible Oils & Ghee", "Spices, Salt & Sugar", "Dairy & Fresh", "Snacks & Biscuits", "Tea, Coffee & Drinks", "Household & Cleaning"];

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
    const base12 = "20" + String(Date.now()).slice(-10);
    let sum = 0;
    for (let i = 0; i < 12; i++) {
      const digit = parseInt(base12[i], 10);
      sum += i % 2 === 0 ? digit : digit * 3;
    }
    const mod = sum % 10;
    const check = mod === 0 ? 0 : 10 - mod;
    setNewProdBarcode(base12 + check);
  };

  const handleAddProduct = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newProdName) return;

    const newProd: WebProduct = {
      id: "p_" + Date.now(),
      name: newProdName,
      categoryName: newProdCat,
      unit: newProdUnit,
      sellingPricePaise: Math.round(parseFloat(newProdSell || "0") * 100),
      mrpPaise: Math.round(parseFloat(newProdMRP || "0") * 100),
      costPricePaise: Math.round(parseFloat(newProdCost || "0") * 100),
      taxRate: parseFloat(newProdTax || "0"),
      currentStock: parseFloat(newProdStock || "0"),
      minStockThreshold: parseFloat(newProdMin || "10"),
      barcode: newProdBarcode || "890" + String(Date.now()).slice(-10),
      isActive: true,
    };

    setProducts([newProd, ...products]);
    setShowAddModal(false);
    setNewProdName("");
    setNewProdBarcode("");
  };

  const formatRupees = (paise: number) => `₹${(paise / 100).toFixed(2)}`;

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />

      <div className="flex-1 flex flex-col min-w-0">
        <Header
          title="Master Product Catalog"
          subtitle="Manage pricing, barcodes, GST slabs, and safety stock thresholds"
        />

        <main className="p-8 space-y-6 flex-1 overflow-auto">
          {/* Top Bar: Search & Actions */}
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4 bg-white p-4 rounded-2xl border border-slate-200/80 shadow-xs">
            <div className="flex items-center gap-3 flex-1">
              <div className="relative flex-1 max-w-md">
                <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Search by name, 13-digit EAN barcode, or HSN code..."
                  className="w-full pl-10 pr-4 py-2 bg-slate-50 hover:bg-slate-100/80 focus:bg-white text-xs text-slate-800 rounded-xl border border-slate-200 focus:border-emerald-500 focus:outline-none transition-all"
                />
              </div>

              {/* Stock Filter */}
              <select
                value={filterStockStatus}
                onChange={(e) => setFilterStockStatus(e.target.value)}
                className="text-xs bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 text-slate-700 font-medium focus:outline-none focus:border-emerald-500"
              >
                <option value="All">All Stock Levels</option>
                <option value="Healthy">Healthy Stock</option>
                <option value="Low">⚠️ Low Stock Alerts</option>
                <option value="Out">❌ Out of Stock</option>
              </select>
            </div>

            <div className="flex items-center gap-3">
              <button
                type="button"
                className="flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 transition-colors"
              >
                <Download className="w-3.5 h-3.5 text-slate-500" /> Export CSV
              </button>
              <button
                type="button"
                onClick={() => setShowAddModal(true)}
                className="flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 shadow-sm shadow-emerald-800/30 transition-all"
              >
                <Plus className="w-4 h-4" /> Add New SKU
              </button>
            </div>
          </div>

          {/* Category Chips */}
          <div className="flex items-center gap-2 overflow-x-auto pb-1 text-xs">
            {categories.map((cat) => (
              <button
                key={cat}
                type="button"
                onClick={() => setSelectedCategory(cat)}
                className={`px-3.5 py-1.5 rounded-xl font-medium transition-all whitespace-nowrap ${
                  selectedCategory === cat
                    ? "bg-slate-900 text-white shadow-xs"
                    : "bg-white text-slate-600 hover:bg-slate-100 border border-slate-200"
                }`}
              >
                {cat}
              </button>
            ))}
          </div>

          {/* Catalog Data Grid */}
          <div className="bg-white rounded-2xl border border-slate-200/80 shadow-xs overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50/80 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                    <th className="py-3.5 px-4">Product Name & Category</th>
                    <th className="py-3.5 px-4">Barcode & HSN</th>
                    <th className="py-3.5 px-4 text-right">Cost Price</th>
                    <th className="py-3.5 px-4 text-right">Selling Price</th>
                    <th className="py-3.5 px-4 text-right">MRP</th>
                    <th className="py-3.5 px-4 text-center">GST Slab</th>
                    <th className="py-3.5 px-4 text-center">Stock Level</th>
                    <th className="py-3.5 px-4 text-right">Gross Margin</th>
                    <th className="py-3.5 px-4 text-center">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-xs text-slate-700 font-medium">
                  {filteredProducts.map((p) => {
                    const marginPaise = p.sellingPricePaise - p.costPricePaise;
                    const marginPct = p.sellingPricePaise > 0 ? ((marginPaise / p.sellingPricePaise) * 100).toFixed(1) : "0.0";
                    const isLowStock = p.currentStock <= p.minStockThreshold;

                    return (
                      <tr key={p.id} className="hover:bg-slate-50/60 transition-colors">
                        <td className="py-3 px-4">
                          <div className="font-bold text-slate-900">{p.name}</div>
                          <div className="text-[11px] text-slate-400 font-normal">{p.categoryName} • Unit: {p.unit}</div>
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
                          {isLowStock ? (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-bold bg-amber-50 text-amber-700 border border-amber-200">
                              <AlertTriangle className="w-3 h-3" /> {p.currentStock} {p.unit} (Low)
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                              <CheckCircle2 className="w-3 h-3" /> {p.currentStock} {p.unit}
                            </span>
                          )}
                        </td>
                        <td className="py-3 px-4 text-right font-mono">
                          <span className="font-bold text-slate-900">{formatRupees(marginPaise)}</span>
                          <span className="text-[10px] text-emerald-600 font-semibold block">({marginPct}%)</span>
                        </td>
                        <td className="py-3 px-4 text-center">
                          <button
                            type="button"
                            className="p-1.5 rounded-lg text-slate-500 hover:bg-slate-100 hover:text-slate-800 transition-colors"
                            title="Edit Product"
                          >
                            <Edit2 className="w-3.5 h-3.5" />
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            <div className="p-4 border-t border-slate-100 bg-slate-50/50 flex items-center justify-between text-xs text-slate-500">
              <span>Showing {filteredProducts.length} of {products.length} products</span>
              <span>All amounts calculated in integer Paise</span>
            </div>
          </div>
        </main>
      </div>

      {/* Add Product Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center z-50 p-4">
          <div className="bg-white w-full max-w-lg rounded-2xl shadow-2xl border border-slate-200 overflow-hidden animate-in fade-in zoom-in-95 duration-150">
            <div className="p-6 border-b border-slate-100 flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <div className="p-2 bg-emerald-100 text-emerald-700 rounded-xl">
                  <Package className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-slate-900 text-base">Add New SKU to Catalog</h3>
                  <p className="text-xs text-slate-500">Register master product details & barcode</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setShowAddModal(false)}
                className="p-1.5 rounded-lg text-slate-400 hover:bg-slate-100 hover:text-slate-700 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleAddProduct} className="p-6 space-y-4 text-xs">
              <div>
                <label className="font-bold text-slate-700 block mb-1">Product Name *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Fortune Mustard Oil 1L Bottle"
                  value={newProdName}
                  onChange={(e) => setNewProdName(e.target.value)}
                  className="w-full px-3.5 py-2.5 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Category</label>
                  <select
                    value={newProdCat}
                    onChange={(e) => setNewProdCat(e.target.value)}
                    className="w-full px-3 py-2.5 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none"
                  >
                    {categories.filter((c) => c !== "All").map((cat) => (
                      <option key={cat} value={cat}>{cat}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Unit</label>
                  <select
                    value={newProdUnit}
                    onChange={(e) => setNewProdUnit(e.target.value)}
                    className="w-full px-3 py-2.5 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none"
                  >
                    <option value="packet">Packet (pcs)</option>
                    <option value="kg">Kilogram (kg)</option>
                    <option value="g">Gram (g)</option>
                    <option value="L">Litre (L)</option>
                  </select>
                </div>
              </div>

              {/* Pricing Row */}
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Cost Price (₹)</label>
                  <input
                    type="number"
                    step="0.01"
                    value={newProdCost}
                    onChange={(e) => setNewProdCost(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none font-mono"
                  />
                </div>
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Selling Price (₹)</label>
                  <input
                    type="number"
                    step="0.01"
                    value={newProdSell}
                    onChange={(e) => setNewProdSell(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none font-mono font-bold text-emerald-700"
                  />
                </div>
                <div>
                  <label className="font-bold text-slate-700 block mb-1">MRP (₹)</label>
                  <input
                    type="number"
                    step="0.01"
                    value={newProdMRP}
                    onChange={(e) => setNewProdMRP(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none font-mono"
                  />
                </div>
              </div>

              {/* Barcode & GST */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <div className="flex items-center justify-between mb-1">
                    <label className="font-bold text-slate-700">13-Digit EAN Barcode</label>
                    <button
                      type="button"
                      onClick={generateAutoEAN}
                      className="text-[10px] text-emerald-600 font-bold hover:underline flex items-center gap-0.5"
                    >
                      <Sparkles className="w-2.5 h-2.5" /> Auto-Gen
                    </button>
                  </div>
                  <input
                    type="text"
                    placeholder="Scan or click Auto-Gen"
                    value={newProdBarcode}
                    onChange={(e) => setNewProdBarcode(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none font-mono"
                  />
                </div>
                <div>
                  <label className="font-bold text-slate-700 block mb-1">GST Tax Rate</label>
                  <select
                    value={newProdTax}
                    onChange={(e) => setNewProdTax(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none"
                  >
                    <option value="0.0">0% (Nil / Exempt)</option>
                    <option value="5.0">5% GST (Oils/Flour)</option>
                    <option value="12.0">12% GST (Butter/Dairy)</option>
                    <option value="18.0">18% GST (Soaps/Biscuits)</option>
                    <option value="28.0">28% GST (Drinks/Luxury)</option>
                  </select>
                </div>
              </div>

              {/* Initial Stock & Threshold */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Initial Opening Stock</label>
                  <input
                    type="number"
                    value={newProdStock}
                    onChange={(e) => setNewProdStock(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none font-mono"
                  />
                </div>
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Min Safety Threshold</label>
                  <input
                    type="number"
                    value={newProdMin}
                    onChange={(e) => setNewProdMin(e.target.value)}
                    className="w-full px-3 py-2 bg-slate-50 rounded-xl border border-slate-200 focus:bg-white focus:border-emerald-500 focus:outline-none font-mono"
                  />
                </div>
              </div>

              <div className="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-600 hover:bg-slate-100"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 shadow-sm shadow-emerald-800/30"
                >
                  Save to Catalog
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
