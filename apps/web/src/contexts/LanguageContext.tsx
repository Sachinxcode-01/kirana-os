"use client";

import React, { createContext, useContext, useState, useEffect } from "react";

export type SupportedLanguage = "en" | "hi" | "kn" | "ta" | "te";

export interface LanguageInfo {
  code: SupportedLanguage;
  name: string;
  nativeName: string;
  flag: string;
  speechLocale: string;
}

export const SUPPORTED_LANGUAGES: LanguageInfo[] = [
  { code: "en", name: "English", nativeName: "English", flag: "🇬🇧", speechLocale: "en-IN" },
  { code: "hi", name: "Hindi", nativeName: "हिंदी", flag: "🇮🇳", speechLocale: "hi-IN" },
  { code: "kn", name: "Kannada", nativeName: "ಕನ್ನಡ", flag: "🇮🇳", speechLocale: "kn-IN" },
  { code: "ta", name: "Tamil", nativeName: "தமிழ்", flag: "🇮🇳", speechLocale: "ta-IN" },
  { code: "te", name: "Telugu", nativeName: "తెలుగు", flag: "🇮🇳", speechLocale: "te-IN" },
];

export const TRANSLATIONS: Record<SupportedLanguage, Record<string, string>> = {
  en: {
    // Navigation
    "nav.pos": "Live POS Counter",
    "nav.dashboard": "Dashboard",
    "nav.catalog": "Inventory & Catalog",
    "nav.udhaar": "Digital Khata",
    "nav.purchases": "Suppliers & PO",
    "nav.gst": "GST Returns",
    "nav.analytics": "Analytics & Z-Report",
    "nav.settings": "Settings & POS Setup",
    "nav.signout": "Sign Out",

    // Header & Actions
    "header.search": "Search or speak command...",
    "header.quickTender": "Quick Tender",
    "header.receipt": "Receipt",
    "header.shortcuts": "Shortcuts",
    "header.alerts": "Store Alerts",
    "header.unmute": "Unmute POS Audio",
    "header.mute": "Mute POS Audio",

    // Dashboard Quick Actions
    "dash.quickActions": "Quick Actions",
    "dash.addSku": "Add SKU",
    "dash.sendKhataReminder": "Send Khata Reminder",
    "dash.replenishPo": "Auto-Replenish PO",
    "dash.exportGst": "Export GSTR-1",
    "dash.cloudOnline": "Cloud Sync: 100% Online",

    // KPIs
    "kpi.revenue": "Today's Revenue",
    "kpi.bills": "Bills Finalized",
    "kpi.udhaar": "Pending Udhaar (Khata)",
    "kpi.skus": "Active Catalog SKUs",
    "kpi.vsYesterday": "vs yesterday",
    "kpi.dueToday": "accounts due today",
    "kpi.lowStockAlerts": "Low Stock alerts",

    // Live Invoices Stream
    "stream.title": "Live Invoices Stream (Counter 01)",
    "stream.subtitle": "Real-time synchronized transactions",
    "stream.billNumber": "Bill Number",
    "stream.time": "Time",
    "stream.customer": "Customer",
    "stream.amount": "Amount",
    "stream.paymentMode": "Payment Mode",
    "stream.quickTender": "Quick Tender",
    "stream.settle": "Settle",

    // Filters
    "filter.all": "ALL",
    "filter.upi": "UPI",
    "filter.cash": "CASH",
    "filter.udhaar": "UDHAAR",

    // General
    "pos.voiceListening": "Listening... Speak product or name",
    "pos.voiceError": "Could not recognize speech. Please retry.",
  },
  hi: {
    // Navigation
    "nav.pos": "पीओएस बिलिंग काउंटर",
    "nav.dashboard": "डैशबोर्ड",
    "nav.catalog": "सामग्री सूची (कैटलॉग)",
    "nav.udhaar": "डिजिटल उधार खाता",
    "nav.purchases": "आपूर्तिकर्ता और खरीद",
    "nav.gst": "जीएसटी रिटर्न",
    "nav.analytics": "बिक्री विश्लेषण व जेड-रिपोर्ट",
    "nav.settings": "सेटिंग्स व पीओएस सेटअप",
    "nav.signout": "लॉग आउट",

    // Header & Actions
    "header.search": "खोजें या बोलकर बताएं...",
    "header.quickTender": "त्वरित रोकड़ (कैश)",
    "header.receipt": "रसीद पर्ची",
    "header.shortcuts": "शॉर्टकट",
    "header.alerts": "दुकान अलर्ट",
    "header.unmute": "ध्वनि चालू करें",
    "header.mute": "ध्वनि म्यूट करें",

    // Dashboard Quick Actions
    "dash.quickActions": "त्वरित कार्य",
    "dash.addSku": "नया सामान जोड़ें",
    "dash.sendKhataReminder": "उधार याद दिलाएं",
    "dash.replenishPo": "नया स्टॉक मंगवाएं",
    "dash.exportGst": "जीएसटीआर-1 डाउनलोड",
    "dash.cloudOnline": "क्लाउड सिंक: 100% सक्रिय",

    // KPIs
    "kpi.revenue": "आज की कुल बिक्री",
    "kpi.bills": "कटे हुए पक्के बिल",
    "kpi.udhaar": "बकाया उधार (खाता)",
    "kpi.skus": "दुकान में कुल सामान",
    "kpi.vsYesterday": "कल के मुकाबले",
    "kpi.dueToday": "खाते आज देय हैं",
    "kpi.lowStockAlerts": "कम स्टॉक की चेतावनी",

    // Live Invoices Stream
    "stream.title": "लाइव बिलिंग काउंटर (काउंटर 01)",
    "stream.subtitle": "वास्तविक समय में दर्ज किए गए बिल",
    "stream.billNumber": "बिल संख्या",
    "stream.time": "समय",
    "stream.customer": "ग्राहक",
    "stream.amount": "रकम",
    "stream.paymentMode": "भुगतान माध्यम",
    "stream.quickTender": "त्वरित रोकड़",
    "stream.settle": "हिसाब करें",

    // Filters
    "filter.all": "सभी",
    "filter.upi": "यूपीआई",
    "filter.cash": "नकद",
    "filter.udhaar": "उधार",

    // General
    "pos.voiceListening": "सुन रहे हैं... उत्पाद या ग्राहक का नाम बोलें",
    "pos.voiceError": "आवाज़ पहचानी नहीं जा सकी। कृपया पुनः प्रयास करें।",
  },
  kn: {
    // Navigation
    "nav.pos": "ಲೈವ್ ಬಿಲ್ಲಿಂಗ್ ಕೌಂಟರ್",
    "nav.dashboard": "ಡ್ಯಾಶ್‌ಬೋರ್ಡ್",
    "nav.catalog": "ದಾಸ್ತಾನು ಮತ್ತು ಕ್ಯಾಟಲಾಗ್",
    "nav.udhaar": "ಡಿಜಿಟಲ್ ಉದ್ರಿ ಖಾತೆ",
    "nav.purchases": "ಸರಬರಾಜುದಾರರು & ಖರೀದಿ",
    "nav.gst": "ಜಿಎಸ್‌ಟಿ ರಿಟರ್ನ್ಸ್",
    "nav.analytics": "ಮಾರಾಟ ವಿಶ್ಲೇಷಣೆ & ಝೆಡ್-ವರದಿ",
    "nav.settings": "ಸೆಟ್ಟಿಂಗ್ಸ್ & ಪಿಒಎಸ್ ಸೆಟಪ್",
    "nav.signout": "ಸೈನ್ ಔಟ್",

    // Header & Actions
    "header.search": "ಹುಡುಕಿ ಅಥವಾ ಧ್ವನಿ ಮೂಲಕ ಆದೇಶಿಸಿ...",
    "header.quickTender": "ತ್ವರಿತ ನಗದು ಲೆಕ್ಕ",
    "header.receipt": "ರಶೀದಿ ಪ್ರಿಂಟ್",
    "header.shortcuts": "ಶಾರ್ಟ್‌ಕಟ್‌ಗಳು",
    "header.alerts": "ಅಂಗಡಿ ಎಚ್ಚರಿಕೆಗಳು",
    "header.unmute": "ಧ್ವನಿ ಆನ್ ಮಾಡಿ",
    "header.mute": "ಧ್ವನಿ ಮ್ಯೂಟ್ ಮಾಡಿ",

    // Dashboard Quick Actions
    "dash.quickActions": "ತ್ವರಿತ ಕ್ರಿಯೆಗಳು",
    "dash.addSku": "ಹೊಸ ವಸ್ತು ಸೇರಿಸಿ",
    "dash.sendKhataReminder": "ಉದ್ರಿ ಜ್ಞಾಪನೆ ಕಳುಹಿಸಿ",
    "dash.replenishPo": "ಸ್ಟಾಕ್ ತರಿಸಿಕೊಳ್ಳಿ",
    "dash.exportGst": "ಜಿಎಸ್‌ಟಿ-1 ರಫ್ತು",
    "dash.cloudOnline": "ಕ್ಲೌಡ್ ಸಿಂಕ್: 100% ಆನ್‌ಲೈನ್",

    // KPIs
    "kpi.revenue": "ಇಂದಿನ ಒಟ್ಟು ಆದಾಯ",
    "kpi.bills": "ರಚಿಸಲಾದ ಬಿಲ್‌ಗಳು",
    "kpi.udhaar": "ಬಾಕಿ ಉದ್ರಿ ಮೊತ್ತ",
    "kpi.skus": "ಸಕ್ರಿಯ ಸಾಮಗ್ರಿಗಳು",
    "kpi.vsYesterday": "ನಿನ್ನೆಗೆ ಹೋಲಿಸಿದರೆ",
    "kpi.dueToday": "ಖಾತೆಗಳು ಇಂದು ಬಾಕಿ ಇವೆ",
    "kpi.lowStockAlerts": "ಕಡಿಮೆ ದಾಸ್ತಾನು ಎಚ್ಚರಿಕೆ",

    // Live Invoices Stream
    "stream.title": "ಲೈವ್ ಬಿಲ್ಲಿಂಗ್ ಕೌಂಟರ್ (ಕೌಂಟರ್ 01)",
    "stream.subtitle": "ನೈಜ ಸಮಯದಲ್ಲಿ ನವೀಕರಿಸಲಾದ ವಹಿವಾಟುಗಳು",
    "stream.billNumber": "ಬಿಲ್ ಸಂಖ್ಯೆ",
    "stream.time": "ಸಮಯ",
    "stream.customer": "ಗ್ರಾಹಕರು",
    "stream.amount": "ಮೊತ್ತ",
    "stream.paymentMode": "ಪಾವತಿ ವಿಧಾನ",
    "stream.quickTender": "ತ್ವರಿತ ನಗದು",
    "stream.settle": "ಲೆಕ್ಕ ಚುಕ್ತಾ",

    // Filters
    "filter.all": "ಎಲ್ಲವೂ",
    "filter.upi": "ಯುಪಿಐ",
    "filter.cash": "ನಗದು",
    "filter.udhaar": "ಉದ್ರಿ",

    // General
    "pos.voiceListening": "ಆಲಿಸಲಾಗುತ್ತಿದೆ... ವಸ್ತುವಿನ ಹೆಸರು ಹೇಳಿ",
    "pos.voiceError": "ಧ್ವನಿ ಗುರುತಿಸಲಾಗಿಲ್ಲ. ದಯವಿಟ್ಟು ಪುನಃ ಪ್ರಯತ್ನಿಸಿ.",
  },
  ta: {
    // Navigation
    "nav.pos": "நேரடி பில்லிங் கவுண்டர்",
    "nav.dashboard": "டாஷ்போர்டு",
    "nav.catalog": "பொருட்கள் பட்டியல்",
    "nav.udhaar": "டிஜிட்டல் கடன் கணக்கு",
    "nav.purchases": "சப்ளையர்கள் & கொள்முதல்",
    "nav.gst": "ஜிஎஸ்டி ரிட்டர்ன்ஸ்",
    "nav.analytics": "விற்பனை பகுப்பாய்வு & இசட்-அறிக்கை",
    "nav.settings": "அமைப்புகள் & பிஓஎஸ்",
    "nav.signout": "வெளியேறு",

    // Header & Actions
    "header.search": "தேடவும் அல்லது குரல் கட்டளை...",
    "header.quickTender": "விரைவு ரொக்கம்",
    "header.receipt": "ரசீது",
    "header.shortcuts": "குறுக்குவழிகள்",
    "header.alerts": "கடை எச்சரிக்கைகள்",
    "header.unmute": "ஒலியை இயக்கவும்",
    "header.mute": "ஒலியை முடக்கவும்",

    // Dashboard Quick Actions
    "dash.quickActions": "விரைவு செயல்கள்",
    "dash.addSku": "புதிய பொருள் சேர்",
    "dash.sendKhataReminder": "கடன் நினைவூட்டல் அனுப்பு",
    "dash.replenishPo": "சரக்கு கொள்முதல்",
    "dash.exportGst": "ஜிஎஸ்டி பதிவிறக்கு",
    "dash.cloudOnline": "கிளவுட் இணைப்பு: 100% தயார்",

    // KPIs
    "kpi.revenue": "இன்றைய மொத்த விற்பனை",
    "kpi.bills": "முடிந்த பில்கள்",
    "kpi.udhaar": "நிலுவை கடன் தொகை",
    "kpi.skus": "பொருட்கள் எண்ணிக்கை",
    "kpi.vsYesterday": "நேற்றை விட",
    "kpi.dueToday": "கணக்குகள் இன்று செலுத்த வேண்டும்",
    "kpi.lowStockAlerts": "குறைந்த இருப்பு எச்சரிக்கை",

    // Live Invoices Stream
    "stream.title": "நேரடி பில்லிங் கவுண்டர் (கவுண்டர் 01)",
    "stream.subtitle": "உடனடி பரிவர்த்தனை பதிவுகள்",
    "stream.billNumber": "பில் எண்",
    "stream.time": "நேரம்",
    "stream.customer": "வாடிக்கையாளர்",
    "stream.amount": "தொகை",
    "stream.paymentMode": "பணம் செலுத்தும் முறை",
    "stream.quickTender": "விரைவு ரொக்கம்",
    "stream.settle": "செட்டில் செய்",

    // Filters
    "filter.all": "அனைத்தும்",
    "filter.upi": "யுபிஐ",
    "filter.cash": "ரொக்கம்",
    "filter.udhaar": "கடன்",

    // General
    "pos.voiceListening": "கேட்கிறது... பொருள் அல்லது பெயர் சொல்லவும்",
    "pos.voiceError": "குரல் கேட்கவில்லை. மீண்டும் முயற்சிக்கவும்.",
  },
  te: {
    // Navigation
    "nav.pos": "లైవ్ బిల్లింగ్ కౌంటర్",
    "nav.dashboard": "డ్యాష్‌బోర్డ్",
    "nav.catalog": "సరుకుల జాబితా (కేటలాగ్)",
    "nav.udhaar": "డిజిటల్ అప్పుల ఖాతా",
    "nav.purchases": "సప్లయర్లు & కొనుగోళ్లు",
    "nav.gst": "జీఎస్టీ రిటర్న్స్",
    "nav.analytics": "అమ్మకాల విశ్లేషణ & జెడ్-రిపోర్ట్",
    "nav.settings": "సెట్టింగులు & పీవోఎస్",
    "nav.signout": "లాగ్ అవుట్",

    // Header & Actions
    "header.search": "వెతకండి లేదా మాట్లాడండి...",
    "header.quickTender": "త్వరిత నగదు లెక్కింపు",
    "header.receipt": "రసీదు ముద్రణ",
    "header.shortcuts": "షార్ట్‌కట్లు",
    "header.alerts": "దుకాణం హెచ్చరికలు",
    "header.unmute": "శబ్దం ఆన్ చేయండి",
    "header.mute": "శబ్దం మ్యూట్ చేయండి",

    // Dashboard Quick Actions
    "dash.quickActions": "త్వరిత చర్యలు",
    "dash.addSku": "కొత్త వస్తువు జోడించు",
    "dash.sendKhataReminder": "బాకీ గుర్తుచేయండి",
    "dash.replenishPo": "కొత్త సరుకు ఆర్డర్",
    "dash.exportGst": "జీఎస్టీఆర్-1 ఎగుమతి",
    "dash.cloudOnline": "క్లౌడ్ సింక్: 100% ఆన్‌లైన్",

    // KPIs
    "kpi.revenue": "నేటి మొత్తం అమ్మకాలు",
    "kpi.bills": "పూర్తయిన బిల్లులు",
    "kpi.udhaar": "బాకీ ఉన్న అప్పుల మొత్తం",
    "kpi.skus": "దుకాణంలోని మొత్తం సరుకులు",
    "kpi.vsYesterday": "నిన్నటితో పోలిస్తే",
    "kpi.dueToday": "ఖాతాలు నేడు చెల్లించాలి",
    "kpi.lowStockAlerts": "తక్కువ సరుకు హెచ్చరికలు",

    // Live Invoices Stream
    "stream.title": "లైవ్ బిల్లింగ్ కౌంటర్ (కౌంటర్ 01)",
    "stream.subtitle": "తాజా లావాదేవీల రికార్డులు",
    "stream.billNumber": "బిల్లు నంబర్",
    "stream.time": "సమయం",
    "stream.customer": "కస్టమర్",
    "stream.amount": "మొత్తం",
    "stream.paymentMode": "చెల్లింపు విధానం",
    "stream.quickTender": "త్వరిత నగదు",
    "stream.settle": "లెక్క సరిచేయు",

    // Filters
    "filter.all": "అన్నీ",
    "filter.upi": "యూపీఐ",
    "filter.cash": "నగదు",
    "filter.udhaar": "అప్పు",

    // General
    "pos.voiceListening": "వింటున్నాము... వస్తువు లేదా పేరు చెప్పండి",
    "pos.voiceError": "వాయిస్ గుర్తించలేకపోయాము. దయచేసి మళ్లీ ప్రయత్నించండి.",
  },
};

interface LanguageContextType {
  language: SupportedLanguage;
  currentLanguage: LanguageInfo;
  setLanguage: (lang: SupportedLanguage) => void;
  t: (key: string) => string;
}

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

const LANGUAGE_STORAGE_KEY = "kirana_language_pref";

export function LanguageProvider({ children }: { children: React.ReactNode }) {
  const [language, setLanguageState] = useState<SupportedLanguage>("en");

  useEffect(() => {
    if (typeof window !== "undefined") {
      const saved = localStorage.getItem(LANGUAGE_STORAGE_KEY) as SupportedLanguage | null;
      if (saved && SUPPORTED_LANGUAGES.some((l) => l.code === saved)) {
        setLanguageState(saved);
      }
    }
  }, []);

  const setLanguage = (lang: SupportedLanguage) => {
    setLanguageState(lang);
    if (typeof window !== "undefined") {
      localStorage.setItem(LANGUAGE_STORAGE_KEY, lang);
    }
  };

  const currentLanguage =
    SUPPORTED_LANGUAGES.find((l) => l.code === language) || SUPPORTED_LANGUAGES[0];

  const t = (key: string): string => {
    const langDict = TRANSLATIONS[language] || TRANSLATIONS.en;
    if (langDict[key]) return langDict[key];
    return TRANSLATIONS.en[key] || key;
  };

  return (
    <LanguageContext.Provider value={{ language, currentLanguage, setLanguage, t }}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  const context = useContext(LanguageContext);
  if (!context) {
    throw new Error("useLanguage must be used within a LanguageProvider");
  }
  return context;
}
