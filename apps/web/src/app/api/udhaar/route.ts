import { NextRequest, NextResponse } from "next/server";
import { KiranaRepository } from "@/lib/db/repository";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const search = searchParams.get("search") || undefined;
    const filter = searchParams.get("filter") || "ALL"; // ALL, OVERDUE, ACTIVE

    const allCustomers = await KiranaRepository.getCustomers(search);
    let customers = allCustomers;

    if (filter === "OVERDUE") {
      customers = customers.filter((c) => c.status === "overdue");
    } else if (filter === "ACTIVE") {
      customers = customers.filter((c) => c.khataBalance > 0);
    }

    const totalKhataPaise = allCustomers.reduce((acc, c) => acc + Math.round(c.khataBalance * 100), 0);
    const overdueCount = allCustomers.filter((c) => c.status === "overdue").length;
    const activeKhataCount = allCustomers.filter((c) => c.khataBalance > 0).length;

    return NextResponse.json({
      success: true,
      customers,
      meta: {
        totalCustomers: allCustomers.length,
        activeKhataCount,
        overdueCount,
        totalKhataPaise,
        totalKhataRupees: totalKhataPaise / 100,
      },
    });
  } catch (err: any) {
    return NextResponse.json(
      { success: false, error: err.message || "Failed to fetch Udhaar ledger" },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { customerId, amountPaise, amountRupees, notes } = body;

    if (!customerId) {
      return NextResponse.json(
        { success: false, error: "customerId is required." },
        { status: 400 }
      );
    }

    const paymentPaise = Number(amountPaise || (amountRupees ? Math.round(amountRupees * 100) : 0));
    if (paymentPaise <= 0) {
      return NextResponse.json(
        { success: false, error: "Payment amount must be greater than zero." },
        { status: 400 }
      );
    }

    const result = await KiranaRepository.recordCustomerRepayment(
      customerId,
      paymentPaise,
      notes || "Udhaar repayment recorded at POS"
    );

    return NextResponse.json({
      success: true,
      result,
      message: `Successfully received payment of ₹${(paymentPaise / 100).toFixed(2)}`,
    });
  } catch (err: any) {
    return NextResponse.json(
      { success: false, error: err.message || "Failed to record Udhaar transaction" },
      { status: 500 }
    );
  }
}
