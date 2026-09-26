import { NextRequest, NextResponse } from "next/server";
import { KiranaRepository } from "@/lib/db/repository";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const suppliers = await KiranaRepository.getSuppliers();
    const totalOutstanding = suppliers.reduce((acc, s) => acc + s.outstandingBalance, 0);

    return NextResponse.json({
      success: true,
      suppliers,
      meta: {
        totalCount: suppliers.length,
        totalOutstanding,
      },
    });
  } catch (err: any) {
    return NextResponse.json(
      { success: false, error: err.message || "Failed to fetch suppliers" },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, phone, contactPerson, gstin, category } = body;

    if (!name || !phone) {
      return NextResponse.json(
        { success: false, error: "Supplier name and phone are required." },
        { status: 400 }
      );
    }

    const createdSupplier = await KiranaRepository.addSupplier({
      name: name.trim(),
      phone: phone.trim(),
      contactPerson: contactPerson ? contactPerson.trim() : undefined,
      gstin: gstin ? gstin.trim() : undefined,
      category: category ? category.trim() : undefined,
    });

    return NextResponse.json(
      { success: true, supplier: createdSupplier },
      { status: 201 }
    );
  } catch (err: any) {
    return NextResponse.json(
      { success: false, error: err.message || "Failed to add supplier" },
      { status: 500 }
    );
  }
}
