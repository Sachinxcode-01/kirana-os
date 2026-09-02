import { NextRequest, NextResponse } from "next/server";
import { KiranaRepository } from "@/lib/db/repository";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const search = searchParams.get("search") || undefined;
  const category = searchParams.get("category") || undefined;
  const lowStockOnly = searchParams.get("lowStock") === "true";

  let products = await KiranaRepository.getProducts(search, category);

  if (lowStockOnly) {
    products = products.filter((p) => p.currentStock <= p.minStock);
  }

  const allProducts = await KiranaRepository.getProducts();
  const lowStockCount = allProducts.filter((p) => p.currentStock <= p.minStock).length;
  const outOfStockCount = allProducts.filter((p) => p.currentStock === 0).length;

  const categories = ["All", ...Array.from(new Set(allProducts.map((p) => p.category)))];

  return NextResponse.json({
    products,
    meta: {
      totalProducts: allProducts.length,
      filteredCount: products.length,
      lowStockCount,
      outOfStockCount,
      categories,
    },
  });
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    if (!body.name || !body.barcode || !body.salePrice) {
      return NextResponse.json(
        { success: false, error: "Missing required product fields: name, barcode, and salePrice are required." },
        { status: 400 }
      );
    }

    const newProduct = await KiranaRepository.addProduct({
      name: body.name.trim(),
      category: body.category || "General",
      barcode: body.barcode.trim(),
      mrp: Number(body.mrp || body.salePrice),
      salePrice: Number(body.salePrice),
      costPrice: Number(body.costPrice || body.salePrice * 0.85),
      currentStock: Number(body.currentStock || 10),
      minStock: Number(body.minStock || 5),
      unit: body.unit || "unit",
      hsn: body.hsn || "19053100",
      gstRate: Number(body.gstRate || 18),
      shelfLocation: body.shelfLocation || "Main Display",
    });

    return NextResponse.json({ success: true, product: newProduct }, { status: 201 });
  } catch (error: any) {
    return NextResponse.json(
      { success: false, error: error.message || "Failed to create product." },
      { status: 500 }
    );
  }
}
