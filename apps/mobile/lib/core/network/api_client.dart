import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../errors/app_exception.dart';

/// Centralized API client wrapping Supabase for remote network interactions.
class ApiClient {
  final supa.SupabaseClient _supabase;

  ApiClient({supa.SupabaseClient? supabase})
      : _supabase = supabase ?? supa.Supabase.instance.client;

  supa.SupabaseClient get supabase => _supabase;

  /// Safe query execution with network exception handling.
  Future<T> safeCall<T>(Future<T> Function(supa.SupabaseClient client) action) async {
    try {
      return await action(_supabase);
    } on supa.PostgrestException catch (e) {
      throw NetworkException(e.message, code: e.code);
    } on supa.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e, st) {
      throw NetworkException('Remote API operation failed: $e', stackTrace: st);
    }
  }
}
