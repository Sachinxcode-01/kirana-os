"use client";

import { useEffect } from "react";

export interface PosHotkeyHandlers {
  onF1?: () => void; // Product Search / Barcode Focus
  onF2?: () => void; // Customer / Khata
  onF4?: () => void; // Quick Cash Tender
  onF8?: () => void; // Re-print Last Bill
  onF12?: () => void; // Finalize Bill
  onHelp?: () => void; // Toggle Shortcuts Help (?)
  onEscape?: () => void; // Close active modal / clear
  onFinalize?: () => void; // Ctrl+Enter Finalize
}

export function usePosHotkeys(handlers: PosHotkeyHandlers) {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const activeEl = document.activeElement;
      const isInputFocused =
        activeEl instanceof HTMLInputElement ||
        activeEl instanceof HTMLTextAreaElement ||
        (activeEl as HTMLElement)?.isContentEditable;

      // Escape always triggers
      if (e.key === "Escape") {
        handlers.onEscape?.();
        return;
      }

      // Ctrl+Enter or Cmd+Enter for instant finalize
      if ((e.ctrlKey || e.metaKey) && e.key === "Enter") {
        e.preventDefault();
        handlers.onFinalize?.();
        return;
      }

      // Function keys (F1, F2, F4, F8, F12)
      if (e.key === "F1") {
        e.preventDefault();
        handlers.onF1?.();
        return;
      }

      if (e.key === "F2") {
        e.preventDefault();
        handlers.onF2?.();
        return;
      }

      if (e.key === "F4") {
        e.preventDefault();
        handlers.onF4?.();
        return;
      }

      if (e.key === "F8") {
        e.preventDefault();
        handlers.onF8?.();
        return;
      }

      if (e.key === "F12") {
        e.preventDefault();
        handlers.onF12?.();
        return;
      }

      // '?' key for shortcuts cheat sheet (only when not typing in an input)
      if (e.key === "?" && !isInputFocused) {
        e.preventDefault();
        handlers.onHelp?.();
        return;
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [handlers]);
}
