import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/bill_model.dart';

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
}
