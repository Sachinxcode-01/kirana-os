import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/app_logger.dart';

class CustomerRemoteDataSource {
  final supabase.SupabaseClient? _client;

  CustomerRemoteDataSource([this._client]);

  supabase.SupabaseClient get _supabase {
    if (_client != null) return _client;
    try {
      return supabase.Supabase.instance.client;
    } catch (e) {
      throw const NetworkException('Supabase client not initialized');
    }
  }

  Future<List<Map<String, dynamic>>> fetchCustomers(String shopId) async {
    try {
      final response =
          await _supabase.from('customers').select().eq('shop_id', shopId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.w('Failed to fetch remote customers: $e',
          tag: 'CustomerRemoteDataSource');
      throw const NetworkException('Unable to fetch customers from cloud');
    }
  }

  Future<void> pushCustomer(Map<String, dynamic> payload) async {
    try {
      await _supabase.from('customers').upsert(payload);
    } catch (e) {
      AppLogger.e('Failed to push customer: $e',
          tag: 'CustomerRemoteDataSource');
      throw const NetworkException('Failed to push customer to cloud');
    }
  }

  Future<void> pushCreditTransaction(Map<String, dynamic> payload) async {
    try {
      await _supabase.from('credit_transactions').upsert(payload);
    } catch (e) {
      AppLogger.e('Failed to push credit transaction: $e',
          tag: 'CustomerRemoteDataSource');
      throw const NetworkException(
          'Failed to push credit transaction to cloud');
    }
  }

  Future<Map<String, dynamic>> recordCreditTransactionAtomic({
    required String shopId,
    required String customerId,
    required int amountPaise,
    required String type,
    String? billId,
    String? notes,
  }) async {
    try {
      final response =
          await _supabase.rpc('record_credit_transaction_atomic', params: {
        'p_shop_id': shopId,
        'p_customer_id': customerId,
        'p_amount_paise': amountPaise,
        'p_type': type,
        'p_bill_id': billId,
        'p_notes': notes,
      });
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      AppLogger.e('Failed atomic credit transaction RPC: $e',
          tag: 'CustomerRemoteDataSource');
      throw NetworkException(
          'Internet connection required to record payment. Cloud error: $e');
    }
  }
}
