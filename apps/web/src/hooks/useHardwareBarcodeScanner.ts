"use client";

import { useEffect, useRef, useCallback } from "react";
import { posAudio } from "@/utils/audioFeedback";

interface HardwareScannerOptions {
  onScan: (barcode: string) => void;
  minBarcodeLength?: number;
  maxInterKeyDelayMs?: number; // Maximum ms between chars for hardware scanners (typically 15-40ms)
  enabled?: boolean;
}

/**
 * High-performance hardware USB/Bluetooth barcode scanner hook.
 * Intercepts HID keystroke bursts across the application and dispatches clean barcode strings
 * with zero UI freezing and sub-5ms processing latency.
 */
export function useHardwareBarcodeScanner({
  onScan,
  minBarcodeLength = 3,
  maxInterKeyDelayMs = 45,
  enabled = true,
}: HardwareScannerOptions) {
  const bufferRef = useRef<string>("");
  const lastKeyTimeRef = useRef<number>(0);
  const scanCountRef = useRef<number>(0);
  const clearTimerRef = useRef<NodeJS.Timeout | null>(null);

  const handleScanComplete = useCallback(
    (scannedBarcode: string) => {
      const cleanBarcode = scannedBarcode.trim();
      if (cleanBarcode.length >= minBarcodeLength) {
        scanCountRef.current += 1;
        posAudio.playRapidScanBeep(scanCountRef.current);
        onScan(cleanBarcode);
      }
      bufferRef.current = "";
    },
    [onScan, minBarcodeLength]
  );

  useEffect(() => {
    if (!enabled) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      // Ignore functional and control keys (Shift, Alt, Ctrl, F1-F12, etc.)
      if (e.key.length > 1 && e.key !== "Enter") {
        return;
      }

      const now = performance.now();
      const delay = now - lastKeyTimeRef.current;
      lastKeyTimeRef.current = now;

      // Clear timer for dangling buffer chars
      if (clearTimerRef.current) {
        clearTimeout(clearTimerRef.current);
      }

      if (e.key === "Enter") {
        // If buffer contains characters accumulated via fast burst
        if (bufferRef.current.length >= minBarcodeLength) {
          e.preventDefault();
          e.stopPropagation();
          handleScanComplete(bufferRef.current);
        } else {
          bufferRef.current = "";
        }
        return;
      }

      // Check inter-key latency: hardware scanners emit keys in rapid succession (< 45ms)
      if (delay < maxInterKeyDelayMs || bufferRef.current.length === 0) {
        bufferRef.current += e.key;

        // Auto-clear buffer if no new characters arrive within 100ms
        clearTimerRef.current = setTimeout(() => {
          bufferRef.current = "";
        }, 100);
      } else {
        // Human typing cadence is much slower (> 100ms) - reset buffer to the latest character
        bufferRef.current = e.key;
      }
    };

    window.addEventListener("keydown", handleKeyDown, true);
    return () => {
      window.removeEventListener("keydown", handleKeyDown, true);
      if (clearTimerRef.current) clearTimeout(clearTimerRef.current);
    };
  }, [enabled, handleScanComplete, maxInterKeyDelayMs, minBarcodeLength]);
}
