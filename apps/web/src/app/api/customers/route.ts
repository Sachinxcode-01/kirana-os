import { NextRequest, NextResponse } from "next/server";
import { KiranaRepository } from "@/lib/db/repository";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const search = searchParams.get("search") || undefined;

  const customers = await KiranaRepository.getCustomers(search);
  const totalKhataPaise = customers.reduce((acc, c) => acc + Math.round(c.khataBalance * 100), 0);
  const overdueCount = customers.filter((c) => c.status === "overdue").length;

  return NextResponse.json({
    customers,
    meta: {
      totalCount: customers.length,
      totalKhataPaise,
      overdueCount,
    },
  });
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, phone, address, creditLimit } = body;

    if (!name || !phone) {
      return NextResponse.json(
        { success: false, error: "Name and phone number are required." },
        { status: 400 }
      );
    }

    // Return created customer
    const newCustomer = {
      id: `cust_${Date.now()}`,
      name: name.trim(),
      phone: phone.trim(),
      address: address || "",
      khataBalance: 0,
      creditLimit: Number(creditLimit || 5000),
      status: "normal" as const,
      lastPaymentDate: new Date().toISOString().split("T")[0],
      overdueDays: 0,
    };

    return NextResponse.json({ success: true, customer: newCustomer }, { status: 201 });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message || "Failed to create customer." },
      { status: 500 }
    );
  }
}
