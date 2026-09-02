import { NextResponse } from "next/server";
import { KiranaRepository } from "@/lib/db/repository";

export const dynamic = "force-dynamic";

export async function GET() {
  const dbHealth = await KiranaRepository.checkHealth();

  return NextResponse.json({
    status: "healthy",
    environment: process.env.NODE_ENV || "development",
    version: "KiranaOS Cloud v2.0 Pro",
    database: {
      mode: dbHealth.mode,
      status: dbHealth.status,
      latencyMs: dbHealth.latencyMs,
      message: dbHealth.message,
    },
    serverTime: new Date().toISOString(),
  });
}
