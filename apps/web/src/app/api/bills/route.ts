import { NextRequest, NextResponse } from "next/server";
import { supabaseAdmin } from "@/lib/supabase/admin";

export const dynamic = "force-dynamic";

interface StoredBillItem {
  name: string;
  qty: number;
  ratePaise: number;
  totalPaise: number;
  hsn?: string;
  unit?: string;
}

interface StoredBill {
  id: string;
  invoiceNumber: string;
  dateStr: string;
  timeStr: string;
  customerName: string;
  customerPhone?: string;
  paymentMode: "Cash" | "UPI QR" | "Udhaar (Khata)" | "Card";
  totalPaise: number;
  subtotalPaise: number;
  taxPaise: number;
  roundOffPaise: number;
  cashierName: string;
  items: StoredBillItem[];
  status: "completed" | "cancelled";
  createdAt: string;
}

// In-memory persistent buffer for live invoices stream
const memoryBills: StoredBill[] = [
  {
    id: "bill-0042",
    invoiceNumber: "INV-2026-0042",
    dateStr: "03 Sep 2026",
    timeStr: "04:32 PM",
    customerName: "Anil Sharma",
    customerPhone: "9880011223",
    paymentMode: "Udhaar (Khata)",
    totalPaise: 185000,
    subtotalPaise: 185000,
    taxPaise: 0,
    roundOffPaise: 0,
    cashierName: "Ramesh Kumar",
    items: [
      { name: "Aashirvaad Shudh Chakki Atta 5kg", qty: 1, ratePaise: 24500, totalPaise: 24500, unit: "packet" },
      { name: "Loose Premium Toor Dal", qty: 2, ratePaise: 16500, totalPaise: 33000, unit: "kg" },
    ],
    status: "completed",
    createdAt: new Date().toISOString(),
  },
  {
    id: "bill-0041",
    invoiceNumber: "INV-2026-0041",
    dateStr: "03 Sep 2026",
    timeStr: "04:15 PM",
    customerName: "Walk-in Retail",
    paymentMode: "UPI QR",
    totalPaise: 34000,
    subtotalPaise: 34000,
    taxPaise: 1619,
    roundOffPaise: 0,
    cashierName: "Ramesh Kumar",
    items: [
      { name: "Fortune Sunlite Oil 1L", qty: 2, ratePaise: 13500, totalPaise: 27000, unit: "packet" },
      { name: "Tata Salt 1kg", qty: 1, ratePaise: 2800, totalPaise: 2800, unit: "packet" },
    ],
    status: "completed",
    createdAt: new Date().toISOString(),
  },
  {
    id: "bill-0040",
    invoiceNumber: "INV-2026-0040",
    dateStr: "03 Sep 2026",
    timeStr: "03:50 PM",
    customerName: "Sunita Patel",
    customerPhone: "9880044556",
    paymentMode: "Cash",
    totalPaise: 82000,
    subtotalPaise: 82000,
    taxPaise: 4100,
    roundOffPaise: 0,
    cashierName: "Ramesh Kumar",
    items: [
      { name: "Surf Excel Easy Wash 1kg", qty: 2, ratePaise: 14000, totalPaise: 28000, unit: "packet" },
    ],
    status: "completed",
    createdAt: new Date().toISOString(),
  },
];

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const mode = searchParams.get("mode"); // CASH, UPI, UDHAAR

  let bills = [...memoryBills];

  if (mode && mode !== "ALL") {
    if (mode === "CASH") bills = bills.filter((b) => b.paymentMode === "Cash");
    if (mode === "UPI") bills = bills.filter((b) => b.paymentMode === "UPI QR");
    if (mode === "UDHAAR") bills = bills.filter((b) => b.paymentMode === "Udhaar (Khata)");
  }

  const totalRevenuePaise = memoryBills.reduce((acc, b) => acc + b.totalPaise, 0);
  const totalBillsCount = memoryBills.length;
  const cashSalesPaise = memoryBills
    .filter((b) => b.paymentMode === "Cash")
    .reduce((acc, b) => acc + b.totalPaise, 0);
  const upiSalesPaise = memoryBills
    .filter((b) => b.paymentMode === "UPI QR")
    .reduce((acc, b) => acc + b.totalPaise, 0);
  const udhaarSalesPaise = memoryBills
    .filter((b) => b.paymentMode === "Udhaar (Khata)")
    .reduce((acc, b) => acc + b.totalPaise, 0);

  return NextResponse.json({
    success: true,
    bills,
    meta: {
      totalBillsCount,
      totalRevenuePaise,
      cashSalesPaise,
      upiSalesPaise,
      udhaarSalesPaise,
      averageBillPaise: totalBillsCount > 0 ? Math.round(totalRevenuePaise / totalBillsCount) : 0,
    },
  });
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    if (!body.items || !Array.isArray(body.items) || body.items.length === 0) {
      return NextResponse.json(
        { success: false, error: "Cannot create bill with zero line items." },
        { status: 400 }
      );
    }

    const now = new Date();
    const newBill: StoredBill = {
      id: `bill-${Date.now()}`,
      invoiceNumber: body.invoiceNumber || `INV-2026-${String(memoryBills.length + 43).padStart(4, "0")}`,
      dateStr: body.dateStr || now.toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" }),
      timeStr: body.timeStr || now.toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" }),
      customerName: body.customerName || "Walk-in Retail",
      customerPhone: body.customerPhone || undefined,
      paymentMode: body.paymentMode || "Cash",
      totalPaise: Number(body.totalPaise || body.totalAmountPaise || 0),
      subtotalPaise: Number(body.subtotalPaise || 0),
      taxPaise: Number(body.taxPaise || body.gstPaise || 0),
      roundOffPaise: Number(body.roundOffPaise || 0),
      cashierName: body.cashierName || "Ramesh Kumar",
      items: body.items.map((i: any) => ({
        name: i.name,
        qty: Number(i.qty || i.quantity || 1),
        ratePaise: Number(i.ratePaise || 0),
        totalPaise: Number(i.totalPaise || i.amountPaise || 0),
        hsn: i.hsnCode || i.hsn,
        unit: i.unit || "unit",
      })),
      status: "completed",
      createdAt: now.toISOString(),
    };

    // Attempt to persist to Supabase if table exists
    try {
      await supabaseAdmin.from("bills").insert([
        {
          bill_number: newBill.invoiceNumber,
          customer_name: newBill.customerName,
          payment_mode: newBill.paymentMode,
          total_paise: newBill.totalPaise,
          items: newBill.items,
        },
      ]);
    } catch {
      // Graceful fallback to in-memory store
    }

    memoryBills.unshift(newBill);

    return NextResponse.json({
      success: true,
      bill: newBill,
    });
  } catch (err: any) {
    return NextResponse.json(
      { success: false, error: err.message || "Failed to process bill" },
      { status: 500 }
    );
  }
}
