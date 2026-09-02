import { NextResponse } from "next/server";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { KiranaRepository } from "@/lib/db/repository";

export const dynamic = "force-dynamic";

export async function GET() {
  const start = Date.now();
  const tablesToProbe = ["shops", "products", "customers", "suppliers", "transactions"];
  const tableResults: Record<string, { exists: boolean; count?: number; error?: string }> = {};

  for (const table of tablesToProbe) {
    try {
      const { data, error, count } = await supabaseAdmin
        .from(table)
        .select("*", { count: "exact", head: true });

      if (error) {
        tableResults[table] = { exists: false, error: error.message };
      } else {
        tableResults[table] = { exists: true, count: count ?? 0 };
      }
    } catch (e: any) {
      tableResults[table] = { exists: false, error: e.message };
    }
  }

  const overallHealth = await KiranaRepository.checkHealth();
  const stats = await KiranaRepository.getDashboardStats();

  return NextResponse.json({
    timestamp: new Date().toISOString(),
    latencyTotalMs: Date.now() - start,
    engine: {
      activeMode: overallHealth.mode,
      status: overallHealth.status,
      message: overallHealth.message,
    },
    credentials: {
      supabaseUrlConfigured: !!process.env.NEXT_PUBLIC_SUPABASE_URL,
      serviceKeyConfigured: !!process.env.SUPABASE_SERVICE_ROLE_KEY,
      anonKeyConfigured: !!process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY,
    },
    schemaDiagnostics: tableResults,
    storeTelemetry: stats,
  });
}
