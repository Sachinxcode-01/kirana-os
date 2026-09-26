import { NextRequest, NextResponse } from "next/server";
import { KiranaRepository, StoredBill } from "@/lib/db/repository";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const mode = searchParams.get("mode") || undefined; // CASH, UPI, UDHAAR, ALL

    const bills = await KiranaRepository.getBills(mode);

    const totalRevenuePaise = bills.reduce((acc, b) => acc + b.totalPaise, 0);
    const totalBillsCount = bills.length;
    const cashSalesPaise = bills
      .filter((b) => b.paymentMode === "Cash")
      .reduce((acc, b) => acc + b.totalPaise, 0);
    const upiSalesPaise = bills
      .filter((b) => b.paymentMode === "UPI QR")
      .reduce((acc, b) => acc + b.totalPaise, 0);
    const udhaarSalesPaise = bills
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
  } catch (err: any) {
    return NextResponse.json(
      { success: false, error: err.message || "Failed to fetch bills" },
      { status: 500 }
    );
  }
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
      id: body.id || `bill-${Date.now()}`,
      invoiceNumber: body.invoiceNumber || `INV-2026-${String(Date.now()).slice(-4)}`,
      dateStr: body.dateStr || now.toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" }),
      timeStr: body.timeStr || now.toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" }),
      customerId: body.customerId || undefined,
      customerName: body.customerName || "Walk-in Retail",
      customerPhone: body.customerPhone || undefined,
      paymentMode: body.paymentMode || "Cash",
      totalPaise: Number(body.totalPaise || body.totalAmountPaise || 0),
      subtotalPaise: Number(body.subtotalPaise || 0),
      taxPaise: Number(body.taxPaise || body.gstPaise || 0),
      roundOffPaise: Number(body.roundOffPaise || 0),
      cashierName: body.cashierName || "Counter 1",
      items: body.items.map((i: any) => ({
        productId: i.productId || i.id,
        name: i.name,
        qty: Number(i.qty || i.quantity || 1),
        ratePaise: Number(i.ratePaise || i.unitPricePaise || 0),
        totalPaise: Number(i.totalPaise || i.amountPaise || 0),
        hsn: i.hsnCode || i.hsn,
        unit: i.unit || "unit",
      })),
      status: "completed",
      createdAt: now.toISOString(),
    };

    const savedBill = await KiranaRepository.createBill(newBill);

    return NextResponse.json({
      success: true,
      bill: savedBill,
    }, { status: 201 });
  } catch (err: any) {
    return NextResponse.json(
      { success: false, error: err.message || "Failed to process bill" },
      { status: 500 }
    );
  }
}
