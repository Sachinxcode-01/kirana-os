// ==============================================================================
// KiranaOS — Supabase Edge Function: generate-upi-qr
// Generates NPCI-compliant dynamic UPI payment links & QR payload
// ==============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

interface UPIRequest {
  upi_id: string;             // Merchant VPA e.g. kirana@okhdfcbank
  merchant_name: string;      // Merchant Name e.g. Sri Lakshmi Provision
  amount_paise: number;       // Exact amount in Paise
  transaction_ref?: string;   // Unique Transaction / Bill reference
  transaction_note?: string;  // Note e.g. Bill INV-2026-001
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const payload: UPIRequest = await req.json();

    if (!payload.upi_id || !payload.amount_paise) {
      return new Response(
        JSON.stringify({ error: "upi_id and amount_paise are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const amountInRupees = (payload.amount_paise / 100).toFixed(2);
    const encodedName = encodeURIComponent(payload.merchant_name || "Kirana Store");
    const encodedNote = encodeURIComponent(payload.transaction_note || "KiranaOS Bill");
    const ref = payload.transaction_ref || `TXN${Date.now()}`;

    // Standard NPCI UPI URI Specification
    const upiUri = `upi://pay?pa=${payload.upi_id}&pn=${encodedName}&am=${amountInRupees}&cu=INR&tr=${ref}&tn=${encodedNote}`;

    // QuickChart / Google Chart QR code image URL for instant on-screen POS display
    const qrImageUrl = `https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${encodeURIComponent(upiUri)}`;

    return new Response(
      JSON.stringify({
        success: true,
        upi_id: payload.upi_id,
        amount_rupees: amountInRupees,
        amount_paise: payload.amount_paise,
        transaction_ref: ref,
        upi_intent_uri: upiUri,
        qr_image_url: qrImageUrl,
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
