import { NextRequest, NextResponse } from "next/server";
import { KiranaRepository } from "@/lib/db/repository";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const report = await KiranaRepository.getZReport();
    return NextResponse.json({
      success: true,
      report,
      timestamp: new Date().toISOString(),
    });
  } catch (err: any) {
    return NextResponse.json(
      { success: false, error: err.message || "Failed to fetch Day-End Z-Report" },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { actualCashPaise, actualCashRupees, notes } = body;

    const actualPaise = Number(
      actualCashPaise !== undefined
        ? actualCashPaise
        : actualCashRupees !== undefined
        ? Math.round(Number(actualCashRupees) * 100)
        : 0
    );

    const closedReport = await KiranaRepository.closeShift(actualPaise, notes);

    return NextResponse.json({
      success: true,
      report: closedReport,
      message: closedReport.isBalanced
        ? "Shift closed successfully with balanced drawer."
        : `Shift closed with ${closedReport.variancePaise > 0 ? "SURPLUS" : "SHORTAGE"} of ₹${Math.abs(closedReport.variancePaise / 100).toFixed(2)}.`,
    });
  } catch (err: any) {
    return NextResponse.json(
      { success: false, error: err.message || "Failed to close shift" },
      { status: 500 }
    );
  }
}
