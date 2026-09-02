// ==============================================================================
// KiranaOS — Supabase Edge Function: send-khata-reminder
// Generates personalized WhatsApp Khata payment reminders with dynamic UPI links
// ==============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

interface KhataReminderPayload {
  shop_name: string;
  shop_phone?: string;
  upi_id: string;
  customer_name: string;
  customer_phone: string;
  balance_paise: number;
  due_days?: number;
  language?: "english" | "hinglish" | "hindi";
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
    const payload: KhataReminderPayload = await req.json();

    if (!payload.customer_phone || !payload.balance_paise || !payload.upi_id) {
      return new Response(
        JSON.stringify({ error: "customer_phone, balance_paise, and upi_id are required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    let cleanPhone = payload.customer_phone.replace(/\D/g, "");
    if (cleanPhone.length === 10) {
      cleanPhone = `91${cleanPhone}`;
    }

    const amountRupees = (payload.balance_paise / 100).toFixed(2);
    const shopName = payload.shop_name || "Kirana Store";
    const encodedName = encodeURIComponent(shopName);
    const note = encodeURIComponent(`Udhaar payment for ${payload.customer_name}`);

    // Direct UPI Payment Intent Link
    const upiLink = `upi://pay?pa=${payload.upi_id}&pn=${encodedName}&am=${amountRupees}&cu=INR&tn=${note}`;

    // WhatsApp Message in Hinglish / English
    let message = "";
    if (payload.language === "hindi") {
      message = `नमस्ते *${payload.customer_name}* जी,\n\n*${shopName}* पर आपका कुल बकाया राशि *₹${amountRupees}* है।\n\nकृपया नीचे दिए गए UPI लिंक पर क्लिक करके भुगतान करें:\n🔗 ${upiLink}\n\nधन्यवाद! 🙏`;
    } else if (payload.language === "hinglish") {
      message = `Namaste *${payload.customer_name}* ji,\n\n*${shopName}* par aapka kul pending udhaar balance *₹${amountRupees}* hai.\n\nKripya neeche diye gaye link se direct UPI payment karein:\n👉 ${upiLink}\n\nKisi bhi query ke liye sampark karein: ${payload.shop_phone || ""}\nDhanyawad! 🙏`;
    } else {
      message = `Dear *${payload.customer_name}*,\n\nThis is a friendly reminder that your pending credit balance at *${shopName}* is *₹${amountRupees}*.\n\nYou can pay instantly via UPI using this link:\n👉 ${upiLink}\n\nThank you for your patronage! 🙏`;
    }

    const encodedText = encodeURIComponent(message);
    const whatsappUrl = `https://wa.me/${cleanPhone}?text=${encodedText}`;

    return new Response(
      JSON.stringify({
        success: true,
        customer_phone: cleanPhone,
        balance_rupees: amountRupees,
        upi_pay_link: upiLink,
        whatsapp_url: whatsappUrl,
        formatted_message: message,
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
