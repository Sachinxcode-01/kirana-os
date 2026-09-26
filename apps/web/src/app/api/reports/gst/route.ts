import { NextRequest, NextResponse } from "next/server";
import { KiranaRepository } from "@/lib/db/repository";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const period = searchParams.get("period") || undefined;

    const gstData = await KiranaRepository.getGstr1Summary();

    return NextResponse.json({
      success: true,
      data: gstData,
      period: period || gstData.filingPeriod,
      timestamp: new Date().toISOString(),
    });
  } catch (err: any) {
    return NextResponse.json(
      { success: false, error: err.message || "Failed to fetch GST summary report" },
      { status: 500 }
    );
  }
}
