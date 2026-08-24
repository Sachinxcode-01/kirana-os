import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../errors/app_exception.dart';

/// Centralized API client wrapping Supabase for remote network interactions.
class ApiClient {
  final supa.SupabaseClient? _client;

  ApiClient({supa.SupabaseClient? supabase}) : _client = supabase;

  supa.SupabaseClient get supabase {
    if (_client != null) return _client;
    return supa.Supabase.instance.client;
  }

  /// Safe query execution with network exception handling.
  Future<T> safeCall<T>(
      Future<T> Function(supa.SupabaseClient client) action) async {
    try {
      return await action(supabase);
    } on supa.PostgrestException catch (e) {
      throw NetworkException(e.message, e.code);
    } on supa.AuthException catch (e) {
      throw AuthException(e.message, e.statusCode);
    } catch (e) {
      throw NetworkException('Remote API operation failed: $e');
    }
  }
}
