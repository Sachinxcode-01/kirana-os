import { NextRequest, NextResponse } from "next/server";
import { supabaseAdmin } from "@/lib/supabase/admin";
import { KiranaRepository, StoredBill } from "@/lib/db/repository";
import { SyncBatchResult } from "@/types/sync";

export const dynamic = "force-dynamic";

// In-memory set of processed operation IDs for deterministic deduplication
const processedOperationIds = new Set<string>();

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const operations = body.operations || body.p_operations;

    if (!Array.isArray(operations) || operations.length === 0) {
      return NextResponse.json(
        { success: false, error: "operations array is required and cannot be empty." },
        { status: 400 }
      );
    }

    const results: SyncBatchResult[] = [];

    // Attempt Supabase RPC execution
    try {
      const { data: rpcResults, error: rpcErr } = await supabaseAdmin.rpc(
        "process_sync_batch",
        { p_operations: operations }
      );

      if (!rpcErr && Array.isArray(rpcResults) && rpcResults.length > 0) {
        return NextResponse.json({
          success: true,
          mode: "supabase_rpc",
          results: rpcResults,
          syncedCount: rpcResults.filter((r: any) => r.status === "SYNCED").length,
        });
      }
    } catch {
      // Fallback to local server-side atomic execution
    }

    // Server-Side Resilient Batch Execution with Idempotency
    for (const op of operations) {
      const opId = op.operation_id || op.operationId;
      const entityType = op.entity_type || op.entityType;
      const payload = op.payload || {};

      if (!opId) {
        results.push({
          operation_id: "unknown",
          status: "FAILED",
          error: "Missing operation_id",
        });
        continue;
      }

      // Idempotency check: Already processed
      if (processedOperationIds.has(opId)) {
        results.push({
          operation_id: opId,
          status: "SYNCED",
          idempotent_duplicate: true,
        });
        continue;
      }

      try {
        if (entityType === "bill") {
          // Bill creation
          const billData = payload.bill || payload;
          const items = payload.items || billData.items || [];
          const now = new Date();

          const newBill: StoredBill = {
            id: billData.id || `bill-${Date.now()}`,
            invoiceNumber: billData.invoiceNumber || billData.bill_number || `INV-2026-${String(Date.now()).slice(-4)}`,
            dateStr: billData.dateStr || now.toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" }),
            timeStr: billData.timeStr || now.toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" }),
            customerId: billData.customerId || billData.customer_id,
            customerName: billData.customerName || "Walk-in Retail",
            customerPhone: billData.customerPhone || billData.customer_phone,
            paymentMode: billData.paymentMode || (billData.payment_mode === "upi_qr" ? "UPI QR" : "Cash"),
            totalPaise: Number(billData.totalPaise || billData.total_paise || 0),
            subtotalPaise: Number(billData.subtotalPaise || billData.subtotal_paise || 0),
            taxPaise: Number(billData.taxPaise || billData.tax_total_paise || 0),
            roundOffPaise: Number(billData.roundOffPaise || 0),
            cashierName: billData.cashierName || "Counter 1",
            items: items.map((i: any) => ({
              productId: i.productId || i.product_id || i.id,
              name: i.name || i.product_name,
              qty: Number(i.qty || i.quantity || 1),
              ratePaise: Number(i.ratePaise || i.unit_price_paise || 0),
              totalPaise: Number(i.totalPaise || i.total_paise || 0),
              hsn: i.hsn || i.hsn_code,
              unit: i.unit || "unit",
            })),
            status: "completed",
            createdAt: now.toISOString(),
          };

          await KiranaRepository.createBill(newBill);
        } else if (entityType === "customer") {
          // Customer registration
          await KiranaRepository.addCustomer({
            name: payload.name || "Customer",
            phone: payload.phone || "0000000000",
            address: payload.address,
            creditLimit: payload.credit_limit || payload.creditLimit,
          });
        } else if (entityType === "payment" || entityType === "credit_transaction") {
          // Repayment / Udhaar transaction
          if (payload.customer_id || payload.customerId) {
            await KiranaRepository.recordCustomerRepayment(
              payload.customer_id || payload.customerId,
              Number(payload.amount_paise || payload.amountPaise || 0),
              payload.notes
            );
          }
        }

        processedOperationIds.add(opId);
        results.push({
          operation_id: opId,
          status: "SYNCED",
        });
      } catch (err: any) {
        results.push({
          operation_id: opId,
          status: "FAILED",
          error: err.message || "Operation mutation failed",
        });
      }
    }

    const syncedCount = results.filter((r) => r.status === "SYNCED").length;

    return NextResponse.json({
      success: true,
      mode: "repository_batch",
      results,
      syncedCount,
    });
  } catch (err: any) {
    return NextResponse.json(
      { success: false, error: err.message || "Batch sync processing error" },
      { status: 500 }
    );
  }
}
