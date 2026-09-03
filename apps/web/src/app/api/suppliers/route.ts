import { NextRequest, NextResponse } from "next/server";
import { KiranaRepository } from "@/lib/db/repository";

export const dynamic = "force-dynamic";

export async function GET() {
  const suppliers = await KiranaRepository.getSuppliers();
  const totalOutstanding = suppliers.reduce((acc, s) => acc + s.outstandingBalance, 0);

  return NextResponse.json({
    suppliers,
    meta: {
      totalCount: suppliers.length,
      totalOutstanding,
    },
  });
}
