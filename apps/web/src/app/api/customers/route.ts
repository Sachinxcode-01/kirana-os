import { NextRequest, NextResponse } from "next/server";
import { KiranaRepository } from "@/lib/db/repository";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const search = searchParams.get("search") || undefined;

    const customers = await KiranaRepository.getCustomers(search);
    const totalKhataPaise = customers.reduce((acc, c) => acc + Math.round(c.khataBalance * 100), 0);
    const overdueCount = customers.filter((c) => c.status === "overdue").length;

    return NextResponse.json({
      success: true,
      customers,
      meta: {
        totalCount: customers.length,
        totalKhataPaise,
        overdueCount,
      },
    });
  } catch (err: any) {
    return NextResponse.json(
      { success: false, error: err.message || "Failed to fetch customers" },
      { status: 500 }
    );
  }
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

    const createdCustomer = await KiranaRepository.addCustomer({
      name: name.trim(),
      phone: phone.trim(),
      address: address ? address.trim() : "",
      creditLimit: Number(creditLimit || 5000),
    });

    return NextResponse.json({ success: true, customer: createdCustomer }, { status: 201 });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message || "Failed to create customer." },
      { status: 500 }
    );
  }
}
