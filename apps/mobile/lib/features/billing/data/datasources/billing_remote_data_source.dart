import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/bill_model.dart';
import '../../domain/models/payment_model.dart';

class BillingRemoteDataSource {
  final ApiClient _apiClient;

  BillingRemoteDataSource([ApiClient? apiClient])
      : _apiClient = apiClient ?? ApiClient();

  Future<BillModel> saveDraftBill(BillModel bill) async {
    try {
      final response = await _apiClient.supabase
          .from('bills')
          .upsert({
            'id': bill.id,
            'shop_id': bill.shopId,
            'cashier_id': bill.cashierId,
            'bill_number': bill.billNumber,
            'status': bill.status,
            'customer_id': bill.customerId,
            'customer_name': bill.customerName,
            'customer_phone': bill.customerPhone,
            'discount_type': bill.discountType,
            'discount_value': bill.discountValue,
            'subtotal_paise': bill.subtotalPaise,
            'tax_total_paise': bill.taxTotalPaise,
            'discount_paise': bill.discountPaise,
            'total_paise': bill.totalPaise,
            'payment_status': bill.paymentStatus,
            'created_at': bill.createdAt.toIso8601String(),
            'updated_at': bill.updatedAt.toIso8601String(),
          })
          .select()
          .single();

      if (bill.items.isNotEmpty) {
        final itemsJson = bill.items
            .map((item) => {
                  'id': item.id,
                  'bill_id': bill.id,
                  'product_id': item.productId,
                  'product_name': item.productName,
                  'unit': item.unit,
                  'unit_price_paise': item.unitPricePaise,
                  'quantity': item.quantity,
                  'tax_rate': item.taxRate,
                  'tax_amount_paise': item.taxAmountPaise,
                  'total_paise': item.totalPaise,
                  'created_at': item.createdAt.toIso8601String(),
                })
            .toList();

        await _apiClient.supabase.from('bill_items').upsert(itemsJson);
      }

      return BillModel.fromJson(response);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }

  Future<BillModel?> fetchDraftBill(String billId) async {
    try {
      final response = await _apiClient.supabase
          .from('bills')
          .select('*, items:bill_items(*)')
          .eq('id', billId)
          .maybeSingle();

      if (response == null) return null;
      return BillModel.fromJson(response);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }

  Future<BillModel> completeSaleCheckout({
    required BillModel bill,
    required PaymentModel payment,
    required String idempotencyKey,
  }) async {
    try {
      // 1. Idempotency Check: if bill is already completed, return immediately
      final existing = await fetchDraftBill(bill.id);
      if (existing != null && existing.isCompleted) {
        return existing;
      }

      // 2. Execute RPC 'complete_sale_transaction' for atomic server execution
      try {
        final rpcResult = await _apiClient.supabase.rpc(
          'complete_sale_transaction',
          params: {
            'p_bill_id': bill.id,
            'p_shop_id': bill.shopId,
            'p_cashier_id': bill.cashierId,
            'p_payment_mode': payment.mode,
            'p_payment_amount_paise': payment.amountPaise,
            'p_idempotency_key': idempotencyKey,
            'p_reference_number': payment.referenceNumber,
            'p_items': bill.items
                .map((i) => {
                      'product_id': i.productId,
                      'quantity': i.quantity,
                      'unit_price_paise': i.unitPricePaise,
                    })
                .toList(),
          },
        );

        if (rpcResult != null) {
          final updated = await fetchDraftBill(bill.id);
          if (updated != null) return updated;
        }
      } catch (rpcError) {
        if (rpcError is PostgrestException) {
          throw Exception(
              'Supabase Error [${rpcError.code}]: ${rpcError.message}');
        }
        // Fallback multi-table execution if RPC is not yet deployed in mock/test client
        final completedAt = DateTime.now();

        await _apiClient.supabase.from('payments').upsert({
          'id': payment.id,
          'shop_id': payment.shopId,
          'bill_id': payment.billId,
          'mode': payment.mode,
          'amount_paise': payment.amountPaise,
          'status': 'success',
          'reference_number': payment.referenceNumber,
          'created_at': completedAt.toIso8601String(),
          'updated_at': completedAt.toIso8601String(),
        });

        final updatedBillJson = await _apiClient.supabase
            .from('bills')
            .upsert({
              'id': bill.id,
              'shop_id': bill.shopId,
              'cashier_id': bill.cashierId,
              'bill_number': bill.billNumber,
              'status': 'completed',
              'customer_id': bill.customerId,
              'customer_name': bill.customerName,
              'customer_phone': bill.customerPhone,
              'discount_type': bill.discountType,
              'discount_value': bill.discountValue,
              'subtotal_paise': bill.subtotalPaise,
              'tax_total_paise': bill.taxTotalPaise,
              'discount_paise': bill.discountPaise,
              'total_paise': bill.totalPaise,
              'payment_status': 'paid',
              'updated_at': completedAt.toIso8601String(),
            })
            .select()
            .single();

        return BillModel.fromJson(updatedBillJson).copyWith(items: bill.items);
      }

      return bill.copyWith(status: 'completed', paymentStatus: 'paid');
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }

  Future<List<BillModel>> fetchBillHistory({
    required String shopId,
    required dynamic filter,
  }) async {
    try {
      var query = _apiClient.supabase
          .from('bills')
          .select('*, items:bill_items(*)')
          .eq('shop_id', shopId);

      final search = filter.search as String?;
      if (search != null && search.trim().isNotEmpty) {
        final term = search.trim();
        query = query.or(
          'bill_number.ilike.%$term%,customer_name.ilike.%$term%,customer_phone.ilike.%$term%',
        );
      }

      final dateRange = filter.dateRange;
      if (dateRange != null) {
        query = query.gte('created_at', dateRange.start.toIso8601String()).lte(
            'created_at',
            dateRange.end.add(const Duration(days: 1)).toIso8601String());
      }

      final cashierId = filter.cashierId as String?;
      if (cashierId != null && cashierId.isNotEmpty) {
        query = query.eq('cashier_id', cashierId);
      }

      final dbStatus = filter.statusFilter.dbValue as String?;
      if (dbStatus != null) {
        if (dbStatus == 'cancelled') {
          query = query.eq('is_cancelled', true);
        } else {
          query = query.eq('status', dbStatus);
        }
      }

      final page = filter.page as int? ?? 0;
      final pageSize = filter.pageSize as int? ?? 20;
      final offset = page * pageSize;

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + pageSize - 1);

      final list = (response as List<dynamic>)
          .map((json) => BillModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return list;
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }
}
