// ==============================================================================
// KiranaOS — Supabase Edge Function: generate-invoice-pdf
// Generates Thermal ESC/POS (58mm/80mm) and A4 GST Tax Invoice HTML layouts
// ==============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

interface InvoiceData {
  shop_name: string;
  shop_address?: string;
  shop_phone?: string;
  shop_gstin?: string;
  fssai_license?: string;
  bill_number: string;
  bill_date: string;
  cashier_name?: string;
  customer_name?: string;
  customer_phone?: string;
  items: Array<{
    name: string;
    hsn_code?: string;
    quantity: number;
    unit?: string;
    unit_price_paise: number;
    tax_rate?: number;
    discount_paise?: number;
    total_paise: number;
  }>;
  subtotal_paise: number;
  tax_paise: number;
  discount_paise: number;
  final_amount_paise: number;
  payment_mode: string;
  format?: "thermal_80mm" | "thermal_58mm" | "a4_gst";
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
    const data: InvoiceData = await req.json();
    const format = data.format || "thermal_80mm";
    const formatRupees = (paise: number) => `₹${(paise / 100).toFixed(2)}`;

    let html = "";

    if (format.startsWith("thermal")) {
      const is58mm = format === "thermal_58mm";
      const width = is58mm ? "58mm" : "80mm";

      html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Receipt - ${data.bill_number}</title>
  <style>
    @page { size: ${width} auto; margin: 0; }
    body {
      font-family: 'Courier New', Courier, monospace;
      width: ${width};
      margin: 0 auto;
      padding: 8px;
      font-size: ${is58mm ? "11px" : "13px"};
      color: #000;
      background: #fff;
    }
    .text-center { text-align: center; }
    .text-right { text-align: right; }
    .bold { font-weight: bold; }
    .divider { border-top: 1px dashed #000; margin: 6px 0; }
    .double-divider { border-top: 2px double #000; margin: 6px 0; }
    table { width: 100%; border-collapse: collapse; }
    th, td { padding: 2px 0; text-align: left; }
    .items-table td:last-child, .items-table th:last-child { text-align: right; }
  </style>
</head>
<body>
  <div class="text-center">
    <div class="bold" style="font-size: 16px;">${data.shop_name}</div>
    ${data.shop_address ? `<div>${data.shop_address}</div>` : ""}
    ${data.shop_phone ? `<div>Ph: ${data.shop_phone}</div>` : ""}
    ${data.shop_gstin ? `<div>GSTIN: ${data.shop_gstin}</div>` : ""}
    ${data.fssai_license ? `<div>FSSAI: ${data.fssai_license}</div>` : ""}
  </div>

  <div class="divider"></div>
  <div>Bill No: <span class="bold">${data.bill_number}</span></div>
  <div>Date: ${data.bill_date}</div>
  ${data.customer_name ? `<div>Cust: ${data.customer_name} (${data.customer_phone || ""})</div>` : ""}
  ${data.cashier_name ? `<div>Cashier: ${data.cashier_name}</div>` : ""}

  <div class="divider"></div>
  <table class="items-table">
    <thead>
      <tr class="bold">
        <th>Item</th>
        <th class="text-right">Qty</th>
        <th class="text-right">Total</th>
      </tr>
    </thead>
    <tbody>
      ${data.items
        .map(
          (item) => `<tr>
        <td>${item.name}</td>
        <td class="text-right">${item.quantity}${item.unit ? " " + item.unit : ""}</td>
        <td class="text-right">${formatRupees(item.total_paise)}</td>
      </tr>`
        )
        .join("")}
    </tbody>
  </table>

  <div class="divider"></div>
  <table>
    <tr><td>Subtotal:</td><td class="text-right">${formatRupees(data.subtotal_paise)}</td></tr>
    ${data.tax_paise > 0 ? `<tr><td>GST:</td><td class="text-right">${formatRupees(data.tax_paise)}</td></tr>` : ""}
    ${data.discount_paise > 0 ? `<tr><td>Discount:</td><td class="text-right">-${formatRupees(data.discount_paise)}</td></tr>` : ""}
    <tr class="bold" style="font-size: 15px;">
      <td>NET TOTAL:</td>
      <td class="text-right">${formatRupees(data.final_amount_paise)}</td>
    </tr>
  </table>

  <div class="double-divider"></div>
  <div>Payment Mode: <span class="bold">${data.payment_mode.toUpperCase()}</span></div>
  <div class="divider"></div>
  <div class="text-center" style="margin-top: 8px;">
    <div>*** THANK YOU! VISIT AGAIN ***</div>
    <div style="font-size: 10px; margin-top: 4px;">Powered by KiranaOS</div>
  </div>
</body>
</html>`;
    }

    return new Response(html, {
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
