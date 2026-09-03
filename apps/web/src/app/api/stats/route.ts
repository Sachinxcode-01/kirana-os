import { NextResponse } from "next/server";
import { KiranaRepository } from "@/lib/db/repository";

export const dynamic = "force-dynamic";

export async function GET() {
  const stats = await KiranaRepository.getDashboardStats();
  return NextResponse.json({
    success: true,
    stats,
    timestamp: new Date().toISOString(),
  });
}
