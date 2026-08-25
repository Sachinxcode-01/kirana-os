import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/shop_settings_model.dart';

class ShopSettingsRemoteDataSource {
  final ApiClient _apiClient;

  ShopSettingsRemoteDataSource([ApiClient? apiClient])
      : _apiClient = apiClient ?? ApiClient();

  Future<ShopSettingsModel> fetchSettings(String shopId) async {
    try {
      final response = await _apiClient.supabase
          .from('shops')
          .select()
          .eq('id', shopId)
          .single();

      return ShopSettingsModel.fromJson(response);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }

  Future<ShopSettingsModel> updateSettings(ShopSettingsModel settings) async {
    try {
      final response = await _apiClient.supabase
          .from('shops')
          .update({
            'name': settings.shopName,
            'phone': settings.phone,
            'address': settings.address,
            'city': settings.city,
            'state': settings.state,
            'pincode': settings.pincode,
            'gstin': settings.gstin,
            'currency': settings.currencySymbol,
            'is_tax_enabled': settings.isTaxEnabled,
            'default_tax_percentage': settings.defaultTaxPercentage,
            'bill_prefix': settings.billPrefix,
            'next_invoice_number': settings.nextInvoiceNumber,
            'show_shop_address': settings.showShopAddress,
            'show_customer_details': settings.showCustomerDetails,
            'show_tax_information': settings.showTaxInformation,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', settings.shopId)
          .select()
          .single();

      return ShopSettingsModel.fromJson(response);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Supabase Error [${e.code}]: ${e.message}');
      }
      rethrow;
    }
  }
}
