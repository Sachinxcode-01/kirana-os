import { NextRequest, NextResponse } from "next/server";
import { KiranaRepository } from "@/lib/db/repository";

export const dynamic = "force-dynamic";

export async function PATCH(request: NextRequest) {
  try {
    const body = await request.json();
    const { productId, delta, reason } = body;

    if (!productId || typeof delta !== "number" || delta === 0) {
      return NextResponse.json(
        { success: false, error: "Valid productId and non-zero numeric delta are required." },
        { status: 400 }
      );
    }

    const auditReason = reason || "Physical Count Reconciliation";
    const res = await KiranaRepository.adjustStock(productId, delta, auditReason);

    if (!res.success) {
      return NextResponse.json(
        { success: false, error: "Product not found or stock adjustment failed." },
        { status: 404 }
      );
    }

    return NextResponse.json({
      success: true,
      productId,
      delta,
      newStock: res.newStock,
      reason: auditReason,
      adjustedAt: new Date().toISOString(),
    });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message || "Internal server error during stock adjustment." },
      { status: 500 }
    );
  }
}
