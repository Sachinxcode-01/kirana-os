"use client";

import React, { useState, useEffect } from "react";
import { motion } from "motion/react";
import { Mic, MicOff, AlertCircle } from "lucide-react";
import { useLanguage } from "@/contexts/LanguageContext";
import { posAudio } from "@/utils/audioFeedback";

interface VoiceSearchButtonProps {
  onResult: (spokenText: string) => void;
  className?: string;
}

export function VoiceSearchButton({ onResult, className = "" }: VoiceSearchButtonProps) {
  const { currentLanguage, t } = useLanguage();
  const [isListening, setIsListening] = useState(false);
  const [isSupported, setIsSupported] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    if (typeof window !== "undefined") {
      const hasSpeech = "webkitSpeechRecognition" in window || "SpeechRecognition" in window;
      setIsSupported(hasSpeech);
    }
  }, []);

  const startListening = () => {
    if (!isSupported || typeof window === "undefined") {
      setErrorMessage("Voice recognition not supported in this browser.");
      return;
    }

    try {
      const SpeechRecognition =
        (window as unknown as { SpeechRecognition?: any }).SpeechRecognition ||
        (window as unknown as { webkitSpeechRecognition?: any }).webkitSpeechRecognition;

      const recognition = new SpeechRecognition();
      recognition.lang = currentLanguage.speechLocale; // e.g. hi-IN, kn-IN, en-IN
      recognition.continuous = false;
      recognition.interimResults = false;

      recognition.onstart = () => {
        setIsListening(true);
        setErrorMessage(null);
        posAudio.playBarcodeBeep();
      };

      recognition.onresult = (event: any) => {
        const transcript = event.results?.[0]?.[0]?.transcript;
        if (transcript) {
          posAudio.playSuccessChime();
          onResult(transcript);
        }
      };

      recognition.onerror = (event: any) => {
        setIsListening(false);
        if (event.error !== "no-speech") {
          setErrorMessage(t("pos.voiceError"));
        }
      };

      recognition.onend = () => {
        setIsListening(false);
      };

      recognition.start();
    } catch {
      setIsListening(false);
      setErrorMessage("Microphone access error.");
    }
  };

  if (!isSupported) return null;

  return (
    <div className="relative inline-flex items-center">
      <motion.button
        whileHover={{ scale: 1.1 }}
        whileTap={{ scale: 0.9 }}
        type="button"
        onClick={startListening}
        className={`relative p-1.5 rounded-lg transition-all cursor-pointer ${
          isListening
            ? "bg-rose-500 text-white shadow-md shadow-rose-500/40"
            : "text-slate-400 hover:text-emerald-600 hover:bg-slate-200/70"
        } ${className}`}
        title={isListening ? t("pos.voiceListening") : `Voice Search (${currentLanguage.nativeName})`}
      >
        {isListening ? (
          <>
            <span className="absolute -top-1 -right-1 flex h-2.5 w-2.5">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-rose-600"></span>
            </span>
            <Mic className="w-3.5 h-3.5 animate-pulse" />
          </>
        ) : (
          <Mic className="w-3.5 h-3.5" />
        )}
      </motion.button>

      {/* Floating Status Tooltip */}
      {isListening && (
        <motion.div
          initial={{ opacity: 0, y: 5 }}
          animate={{ opacity: 1, y: 0 }}
          className="absolute left-1/2 -translate-x-1/2 top-full mt-2 px-2.5 py-1 bg-slate-900 text-white text-[10px] font-bold rounded-lg shadow-lg whitespace-nowrap z-50 flex items-center gap-1.5 pointer-events-none"
        >
          <span className="w-1.5 h-1.5 rounded-full bg-rose-500 animate-ping"></span>
          <span>{t("pos.voiceListening")}</span>
        </motion.div>
      )}
    </div>
  );
}
