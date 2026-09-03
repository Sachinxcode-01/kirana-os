"use client";

import React, { useState, useRef, useEffect } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  Sparkles,
  X,
  Send,
  Bot,
  User,
  TrendingUp,
  AlertTriangle,
  Calendar,
  Gift,
  ArrowRight,
  RefreshCw,
  Coins,
  ShieldCheck,
  CheckCircle2,
  Clock,
  Mic,
} from "lucide-react";
import { VoiceSearchButton } from "@/components/pos/VoiceSearchButton";
import { posAudio } from "@/utils/audioFeedback";

interface KiranaAiCopilotDrawerProps {
  isOpen: boolean;
  onClose: () => void;
}

interface ChatMessage {
  id: string;
  sender: "ai" | "user";
  time: string;
  text: string;
  cardType?: "reorder" | "festive" | "bundle" | "udhaar" | "summary";
  cardData?: any;
}

export function KiranaAiCopilotDrawer({ isOpen, onClose }: KiranaAiCopilotDrawerProps) {
  const [messages, setMessages] = useState<ChatMessage[]>([
    {
      id: "m1",
      sender: "ai",
      time: "Just now",
      text: "Namaste Ramesh ji! 🙏 I am your **KiranaOS AI Store Copilot**. Ask me anything in English, Hindi, or Hinglish about sales, low stock reorder points, festive demand surges, or customer khata.",
      cardType: "summary",
    },
  ]);
  const [inputQuery, setInputQuery] = useState("");
  const [isThinking, setIsThinking] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, isThinking]);

  if (!isOpen) return null;

  const quickPrompts = [
    "Aaj kitna toor dal bika?",
    "Low stock items ka reorder order generate karo",
    "Diwali/Festive surge multiplier check karo",
    "Slow-moving stock bundle combos suggest karo",
  ];

  const handleSend = (textToSend?: string) => {
    const query = (textToSend || inputQuery).trim();
    if (!query) return;

    posAudio.playBarcodeBeep();
    const userMsg: ChatMessage = {
      id: `u-${Date.now()}`,
      sender: "user",
      time: new Date().toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" }),
      text: query,
    };

    setMessages((prev) => [...prev, userMsg]);
    setInputQuery("");
    setIsThinking(true);

    // AI Heuristic & Vernacular Engine Simulation (Phase 18 Specs)
    setTimeout(() => {
      setIsThinking(false);
      posAudio.playSuccessChime();

      const lower = query.toLowerCase();
      let aiResponse: ChatMessage;

      if (lower.includes("reorder") || lower.includes("stock") || lower.includes("कम")) {
        aiResponse = {
          id: `ai-${Date.now()}`,
          sender: "ai",
          time: new Date().toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" }),
          text: "Here is your **Intelligent Reorder Forecast (Phase 18 Algorithm)** using `(Daily Velocity × Lead Time) + Safety Stock`. 3 critical SKUs have breached safety thresholds today:",
          cardType: "reorder",
          cardData: [
            { name: "Brooke Bond Red Label Tea 500g", current: 3, rpo: 15, supplier: "ITC Bangalore Depot", orderQty: 24 },
            { name: "Amul Pasteurised Butter 500g", current: 7, rpo: 12, supplier: "Amul Dairy Agency", orderQty: 30 },
            { name: "Aashirvaad Shudh Atta 10kg", current: 2, rpo: 10, supplier: "ITC Distribution", orderQty: 20 },
          ],
        };
      } else if (lower.includes("diwali") || lower.includes("festive") || lower.includes("tyohar") || lower.includes("त्यौहार")) {
        aiResponse = {
          id: `ai-${Date.now()}`,
          sender: "ai",
          time: new Date().toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" }),
          text: "🎉 **Upcoming Festival Demand Surge Advisory:** Next month's seasonal index indicates an expected **2.4× volume surge** across dairy, flour, and edible oil categories. Prepare inward stock allocations now:",
          cardType: "festive",
          cardData: {
            festival: "Navratri & Diwali Surge (Oct 2026)",
            multiplier: "2.4× Normal Volume",
            highDemandSkus: ["Madhur Sugar M-30", "Fortune Refined Oil", "Aashirvaad Chakki Atta", "Amul Pure Ghee"],
            recommendedSafetyDays: 21,
          },
        };
      } else if (lower.includes("bundle") || lower.includes("combo") || lower.includes("slow") || lower.includes("dead")) {
        aiResponse = {
          id: `ai-${Date.now()}`,
          sender: "ai",
          time: new Date().toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" }),
          text: "💡 **Dead Stock Liquidation Pairing:** I detected that **Basmati Rice Feast 1kg** (35 days holding) has slowed down. You can liquidate it by pairing it with fast-moving **Sunflower Oil 1L**:",
          cardType: "bundle",
          cardData: {
            title: "Super Saver Kitchen Combo",
            itemA: "India Gate Basmati Rice 1kg (Slow)",
            itemB: "Fortune Sunlite Sunflower Oil 1L (Fast)",
            combinedMrp: 260,
            comboOfferPrice: 225,
            marginPreserved: "18.4%",
          },
        };
      } else if (lower.includes("dal") || lower.includes("toor") || lower.includes("बिका") || lower.includes("sales")) {
        aiResponse = {
          id: `ai-${Date.now()}`,
          sender: "ai",
          time: new Date().toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" }),
          text: "📊 **Today's Sales Breakdown for Loose Pulses & Dals:**\n• **Loose Toor Dal:** 18.5 kg sold (₹3,052.50 revenue)\n• Average selling price: ₹165.00/kg\n• Remaining balance in barrel: **66.5 kg** (Comfortably above 15kg safety buffer).",
        };
      } else {
        aiResponse = {
          id: `ai-${Date.now()}`,
          sender: "ai",
          time: new Date().toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" }),
          text: `Got your inquiry: "${query}". All POS registers are synchronized with cloud telemetry. Total revenue today is **₹24,500.00** across 42 finalized bills, with zero shift cash variances.`,
        };
      }

      setMessages((prev) => [...prev, aiResponse]);
    }, 600);
  };

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex justify-end">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
          className="fixed inset-0 bg-slate-950/60 backdrop-blur-xs cursor-pointer"
        />

        {/* Drawer Window */}
        <motion.div
          initial={{ x: "100%" }}
          animate={{ x: 0 }}
          exit={{ x: "100%" }}
          transition={{ type: "spring", stiffness: 300, damping: 30 }}
          className="relative w-full max-w-md bg-slate-900 border-l border-slate-700/80 shadow-2xl flex flex-col h-full z-10 text-slate-100"
        >
          {/* Header */}
          <div className="p-4 border-b border-slate-800 bg-slate-950/90 flex items-center justify-between shrink-0">
            <div className="flex items-center gap-2.5">
              <div className="p-2 bg-gradient-to-tr from-emerald-600 via-teal-500 to-emerald-400 rounded-xl shadow-md shadow-emerald-950/50">
                <Sparkles className="w-5 h-5 text-white animate-pulse" />
              </div>
              <div>
                <h3 className="font-extrabold text-sm text-white flex items-center gap-2">
                  <span>Kirana AI Assistant</span>
                  <span className="text-[10px] font-mono px-1.5 py-0.2 rounded bg-emerald-950 text-emerald-300 border border-emerald-800">
                    Phase 18
                  </span>
                </h3>
                <p className="text-[11px] text-slate-400">Vernacular Kirana Copilot &amp; Forecasting</p>
              </div>
            </div>

            <button
              onClick={onClose}
              className="p-1.5 text-slate-400 hover:text-white rounded-lg hover:bg-slate-800 transition-colors"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Chat Messages Body */}
          <div className="flex-1 overflow-y-auto p-4 space-y-4">
            {messages.map((m) => {
              const isAi = m.sender === "ai";
              return (
                <motion.div
                  key={m.id}
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  className={`flex gap-2.5 ${isAi ? "items-start" : "items-start justify-end"}`}
                >
                  {isAi && (
                    <div className="w-7 h-7 rounded-xl bg-emerald-900/60 border border-emerald-700 text-emerald-300 flex items-center justify-center shrink-0 text-xs font-bold mt-0.5">
                      <Bot className="w-4 h-4" />
                    </div>
                  )}

                  <div className={`max-w-[85%] space-y-2`}>
                    <div
                      className={`p-3.5 rounded-2xl text-xs leading-relaxed ${
                        isAi
                          ? "bg-slate-800 border border-slate-700/80 text-slate-200"
                          : "bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-medium"
                      }`}
                    >
                      <p className="whitespace-pre-line">{m.text}</p>
                    </div>

                    {/* Dynamic Card: Reorder Point Forecast */}
                    {m.cardType === "reorder" && m.cardData && (
                      <div className="p-3 bg-slate-950 border border-slate-700 rounded-xl space-y-2 text-xs">
                        <div className="flex items-center justify-between text-[11px] font-bold text-amber-400 uppercase">
                          <span className="flex items-center gap-1">
                            <AlertTriangle className="w-3.5 h-3.5" /> Suggested Inward POs
                          </span>
                          <span>3 Items Breached</span>
                        </div>
                        <div className="space-y-1.5">
                          {m.cardData.map((item: any, i: number) => (
                            <div
                              key={i}
                              className="p-2 bg-slate-900 rounded-lg flex items-center justify-between"
                            >
                              <div>
                                <p className="font-bold text-white text-[11px]">{item.name}</p>
                                <p className="text-[10px] text-slate-400">
                                  Stock: {item.current} • ROP: {item.rpo} • {item.supplier}
                                </p>
                              </div>
                              <span className="px-2 py-0.5 rounded bg-emerald-950 text-emerald-300 border border-emerald-800 text-[10px] font-bold shrink-0">
                                +{item.orderQty} units
                              </span>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}

                    {/* Dynamic Card: Festive Demand Surge */}
                    {m.cardType === "festive" && m.cardData && (
                      <div className="p-3 bg-gradient-to-br from-amber-950/40 to-orange-950/20 border border-amber-800/60 rounded-xl space-y-2 text-xs">
                        <div className="flex items-center justify-between">
                          <span className="font-extrabold text-amber-300 text-xs">
                            {m.cardData.festival}
                          </span>
                          <span className="px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-300 border border-amber-500/40 text-[10px] font-black">
                            {m.cardData.multiplier}
                          </span>
                        </div>
                        <div className="text-[11px] text-slate-300">
                          High demand items: {m.cardData.highDemandSkus.join(", ")}
                        </div>
                        <div className="text-[10px] text-slate-400 font-medium">
                          Buffer: Keep at least {m.cardData.recommendedSafetyDays} days of forward safety stock.
                        </div>
                      </div>
                    )}

                    {/* Dynamic Card: Combo Bundle Suggestion */}
                    {m.cardType === "bundle" && m.cardData && (
                      <div className="p-3 bg-teal-950/40 border border-teal-800/60 rounded-xl space-y-2 text-xs">
                        <div className="flex items-center justify-between text-teal-300 font-bold">
                          <span className="flex items-center gap-1">
                            <Gift className="w-3.5 h-3.5" /> {m.cardData.title}
                          </span>
                          <span className="text-[10px] bg-teal-900 text-teal-200 px-1.5 py-0.2 rounded font-mono">
                            {m.cardData.marginPreserved} Margin
                          </span>
                        </div>
                        <p className="text-[11px] text-slate-300">
                          {m.cardData.itemA} + {m.cardData.itemB}
                        </p>
                        <div className="flex items-baseline justify-between pt-1 border-t border-teal-800/40">
                          <span className="text-[10px] text-slate-400 line-through">
                            MRP: ₹{m.cardData.combinedMrp}
                          </span>
                          <span className="font-mono font-black text-emerald-400 text-sm">
                            Offer: ₹{m.cardData.comboOfferPrice}
                          </span>
                        </div>
                      </div>
                    )}

                    <div className="text-[10px] text-slate-500 px-1">{m.time}</div>
                  </div>

                  {!isAi && (
                    <div className="w-7 h-7 rounded-xl bg-slate-800 border border-slate-700 text-slate-300 flex items-center justify-center shrink-0 text-xs font-bold mt-0.5">
                      <User className="w-4 h-4" />
                    </div>
                  )}
                </motion.div>
              );
            })}

            {isThinking && (
              <div className="flex items-center gap-2 text-xs text-slate-400 p-2">
                <Bot className="w-4 h-4 text-emerald-400 animate-spin" />
                <span className="animate-pulse">Analyzing store sales &amp; forecasting stock...</span>
              </div>
            )}

            <div ref={messagesEndRef} />
          </div>

          {/* Quick Question Chips */}
          <div className="px-4 py-2 border-t border-slate-800/80 bg-slate-950/40 flex items-center gap-1.5 overflow-x-auto no-scrollbar shrink-0">
            {quickPrompts.map((p, idx) => (
              <button
                key={idx}
                type="button"
                onClick={() => handleSend(p)}
                className="px-2.5 py-1 rounded-lg text-[11px] bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white border border-slate-700/60 whitespace-nowrap transition-colors cursor-pointer"
              >
                {p}
              </button>
            ))}
          </div>

          {/* Input Bar with Voice Button */}
          <div className="p-3 sm:p-4 border-t border-slate-800 bg-slate-950 flex items-center gap-2 shrink-0">
            <div className="relative flex-1">
              <input
                type="text"
                value={inputQuery}
                onChange={(e) => setInputQuery(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleSend()}
                placeholder="Ask in Hindi, Hinglish, or English..."
                className="w-full pl-3 pr-10 py-2.5 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/50"
              />
            </div>

            <VoiceSearchButton
              onResult={(text: string) => {
                setInputQuery(text);
                handleSend(text);
              }}
            />

            <button
              type="button"
              onClick={() => handleSend()}
              disabled={!inputQuery.trim()}
              className="p-2.5 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 disabled:opacity-40 text-white transition-all cursor-pointer shadow-md shadow-emerald-950/50"
            >
              <Send className="w-4 h-4" />
            </button>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
}
