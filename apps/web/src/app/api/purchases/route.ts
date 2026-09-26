import { NextRequest, NextResponse } from "next/server";
import { KiranaRepository } from "@/lib/db/repository";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const purchases = await KiranaRepository.getPurchases();
    const totalPurchasesPaise = purchases.reduce((acc, p) => acc + p.totalPaise, 0);

    return NextResponse.json({
      success: true,
      purchases,
      meta: {
        totalCount: purchases.length,
        totalPurchasesPaise,
        totalPurchasesRupees: totalPurchasesPaise / 100,
      },
    });
  } catch (err: any) {
    return NextResponse.json(
      { success: false, error: err.message || "Failed to fetch purchase orders" },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { supplierId, supplierName, invoiceNumber, invoiceDate, totalPaise, items } = body;

    if (!supplierId || !invoiceNumber || !items || !Array.isArray(items) || items.length === 0) {
      return NextResponse.json(
        { success: false, error: "supplierId, invoiceNumber, and at least one item are required." },
        { status: 400 }
      );
    }

    const calculatedTotalPaise = Number(
      totalPaise ||
      items.reduce((acc: number, item: any) => acc + (Number(item.quantity || 1) * Number(item.purchasePricePaise || 0)), 0)
    );

    const newPurchase = await KiranaRepository.createPurchase({
      supplierId,
      supplierName: supplierName || "Supplier",
      invoiceNumber: invoiceNumber.trim(),
      invoiceDate: invoiceDate || new Date().toISOString().split("T")[0],
      totalPaise: calculatedTotalPaise,
      items: items.map((i: any) => ({
        productId: i.productId,
        productName: i.productName || "Product SKU",
        quantity: Number(i.quantity || 1),
        purchasePricePaise: Number(i.purchasePricePaise || 0),
      })),
    });

    return NextResponse.json(
      { success: true, purchase: newPurchase },
      { status: 201 }
    );
  } catch (err: any) {
    return NextResponse.json(
      { success: false, error: err.message || "Failed to record purchase" },
      { status: 500 }
    );
  }
}
