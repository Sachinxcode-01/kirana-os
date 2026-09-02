// ==============================================================================
// KiranaOS — Supabase Edge Function: send-whatsapp-receipt
// Formats high-conversion WhatsApp digital invoice & click-to-chat intent
// ==============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

interface WhatsAppReceiptPayload {
  shop_name: string;
  shop_phone: string;
  customer_phone: string;
  customer_name?: string;
  bill_number: string;
  bill_date: string;
  items: Array<{
    name: string;
    quantity: number;
    unit?: string;
    total_paise: number;
  }>;
  subtotal_paise: number;
  tax_paise: number;
  discount_paise: number;
  final_amount_paise: number;
  payment_mode: string;
  upi_id?: string;
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
    const payload: WhatsAppReceiptPayload = await req.json();

    if (!payload.customer_phone || !payload.bill_number) {
      return new Response(
        JSON.stringify({ error: "customer_phone and bill_number are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Clean phone number (Indian standard: 10 digits prefixed by 91)
    let cleanPhone = payload.customer_phone.replace(/\D/g, "");
    if (cleanPhone.length === 10) {
      cleanPhone = `91${cleanPhone}`;
    }

    // Format Paise to Rupees
    const formatRupees = (paise: number) => `₹${(paise / 100).toFixed(2)}`;

    // Build WhatsApp message
    let msg = `🛒 *${payload.shop_name.toUpperCase()}*\n`;
    msg += `📄 *Bill No:* ${payload.bill_number}\n`;
    msg += `📅 *Date:* ${payload.bill_date || new Date().toLocaleDateString("en-IN")}\n`;
    if (payload.customer_name) {
      msg += `👤 *Customer:* ${payload.customer_name}\n`;
    }
    msg += `━━━━━━━━━━━━━━━━━━━━━\n`;
    msg += `*ITEMS PURCHASED:*\n`;

    payload.items.forEach((item, idx) => {
      const unit = item.unit ? ` ${item.unit}` : "";
      msg += `${idx + 1}. *${item.name}* × ${item.quantity}${unit} = ${formatRupees(item.total_paise)}\n`;
    });

    msg += `━━━━━━━━━━━━━━━━━━━━━\n`;
    if (payload.discount_paise > 0) {
      msg += `🎉 *Discount Saved:* ${formatRupees(payload.discount_paise)}\n`;
    }
    msg += `💰 *TOTAL AMOUNT:* *${formatRupees(payload.final_amount_paise)}*\n`;
    msg += `💳 *Paid Via:* ${payload.payment_mode.toUpperCase()}\n`;
    msg += `━━━━━━━━━━━━━━━━━━━━━\n`;
    msg += `_Thank you for shopping with us! Please visit again._ 🙏\n`;
    msg += `📞 Support: ${payload.shop_phone || "Contact Store"}\n`;

    const encodedText = encodeURIComponent(msg);
    const waLink = `https://wa.me/${cleanPhone}?text=${encodedText}`;

    return new Response(
      JSON.stringify({
        success: true,
        customer_phone: cleanPhone,
        whatsapp_url: waLink,
        formatted_message: msg,
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
