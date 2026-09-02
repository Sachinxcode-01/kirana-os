"use client";

import React from "react";
import { motion } from "motion/react";
import { Delete, Shuffle, RefreshCw } from "lucide-react";

interface VirtualKeypadProps {
  onDigit: (digit: string) => void;
  onDelete: () => void;
  onClear: () => void;
  isScrambled?: boolean;
  onToggleScramble?: () => void;
}

export function VirtualKeypad({
  onDigit,
  onDelete,
  onClear,
  isScrambled = false,
  onToggleScramble,
}: VirtualKeypadProps) {
  const defaultKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9"];
  const [keys, setKeys] = React.useState(defaultKeys);

  React.useEffect(() => {
    if (isScrambled) {
      setKeys([...defaultKeys].sort(() => Math.random() - 0.5));
    } else {
      setKeys(defaultKeys);
    }
  }, [isScrambled]);

  return (
    <div className="w-full max-w-xs mx-auto space-y-2 select-none">
      <div className="flex items-center justify-between px-1 text-[11px] text-slate-400 font-semibold">
        <span>Touch Numeric Pad</span>
        {onToggleScramble && (
          <button
            type="button"
            onClick={onToggleScramble}
            className={`flex items-center gap-1 transition-colors cursor-pointer ${
              isScrambled ? "text-emerald-400 font-bold" : "text-slate-500 hover:text-slate-300"
            }`}
            title="Scramble keypad layout to prevent shoulder surfing"
          >
            <Shuffle className="w-3 h-3" />
            <span>Anti-Surfing</span>
          </button>
        )}
      </div>

      <div className="grid grid-cols-3 gap-2">
        {keys.map((k) => (
          <motion.button
            key={k}
            whileHover={{ scale: 1.04, backgroundColor: "rgba(255, 255, 255, 0.12)" }}
            whileTap={{ scale: 0.94, backgroundColor: "rgba(16, 185, 129, 0.25)" }}
            type="button"
            onClick={() => onDigit(k)}
            className="h-12 bg-slate-800/80 hover:bg-slate-700/80 border border-slate-700/70 rounded-2xl text-white font-mono font-bold text-lg flex items-center justify-center shadow-md shadow-black/40 transition-colors cursor-pointer"
          >
            {k}
          </motion.button>
        ))}

        {/* Clear Button */}
        <motion.button
          whileHover={{ scale: 1.04, backgroundColor: "rgba(244, 63, 94, 0.15)" }}
          whileTap={{ scale: 0.94 }}
          type="button"
          onClick={onClear}
          className="h-12 bg-rose-950/40 hover:bg-rose-900/40 border border-rose-800/40 rounded-2xl text-rose-300 font-bold text-xs flex items-center justify-center transition-colors cursor-pointer uppercase tracking-wider"
        >
          Clear
        </motion.button>

        {/* Zero */}
        <motion.button
          whileHover={{ scale: 1.04, backgroundColor: "rgba(255, 255, 255, 0.12)" }}
          whileTap={{ scale: 0.94, backgroundColor: "rgba(16, 185, 129, 0.25)" }}
          type="button"
          onClick={() => onDigit("0")}
          className="h-12 bg-slate-800/80 hover:bg-slate-700/80 border border-slate-700/70 rounded-2xl text-white font-mono font-bold text-lg flex items-center justify-center shadow-md shadow-black/40 transition-colors cursor-pointer"
        >
          0
        </motion.button>

        {/* Backspace Button */}
        <motion.button
          whileHover={{ scale: 1.04, backgroundColor: "rgba(255, 255, 255, 0.12)" }}
          whileTap={{ scale: 0.94 }}
          type="button"
          onClick={onDelete}
          className="h-12 bg-slate-800/80 hover:bg-slate-700/80 border border-slate-700/70 rounded-2xl text-slate-300 font-bold flex items-center justify-center transition-colors cursor-pointer"
          title="Backspace"
        >
          <Delete className="w-5 h-5" />
        </motion.button>
      </div>
    </div>
  );
}
