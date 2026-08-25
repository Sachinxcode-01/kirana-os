import 'dart:convert';
import 'package:http/http.dart' as http;
import '../errors/failure.dart';
import '../errors/result.dart';

/// Data model representing the address lookup result from India Post.
class PincodeResult {
  final String state;
  final String district;
  final List<String> localities;

  const PincodeResult({
    required this.state,
    required this.district,
    required this.localities,
  });
}

/// Service to lookup Indian postal address details using India Post's public API.
class PincodeService {
  static const String _baseUrl = 'https://api.postalpincode.in/pincode/';

  /// Fetches address details (State, District, Localities) for a given 6-digit PIN code.
  Future<Result<PincodeResult, Failure>> fetchAddressFromPincode(
    String pincode, {
    http.Client? client,
  }) async {
    final cleanPincode = pincode.trim();
    if (cleanPincode.length != 6 || int.tryParse(cleanPincode) == null) {
      return const ErrorResult(
        ValidationFailure('Invalid PIN code format. Must be 6 numeric digits.'),
      );
    }

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      final uri = Uri.parse('$_baseUrl$cleanPincode');
      final response = await httpClient.get(uri).timeout(
            const Duration(seconds: 8),
          );

      if (response.statusCode != 200) {
        return const ErrorResult(
          NetworkFailure('Could not fetch address. Check your connection.'),
        );
      }

      final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
      if (jsonList.isEmpty) {
        return const ErrorResult(
          ValidationFailure('No address found for this PIN code.'),
        );
      }

      final firstItem = jsonList.first as Map<String, dynamic>;
      final status = firstItem['Status'] as String?;
      final postOfficeList = firstItem['PostOffice'] as List<dynamic>?;

      if (status != 'Success' ||
          postOfficeList == null ||
          postOfficeList.isEmpty) {
        return const ErrorResult(
          ValidationFailure('No address found for this PIN code.'),
        );
      }

      final localities = <String>[];
      String? state;
      String? district;

      for (final office in postOfficeList) {
        if (office is Map<String, dynamic>) {
          final name = office['Name'] as String?;
          if (name != null && name.trim().isNotEmpty) {
            localities.add(name.trim());
          }
          state ??= office['State'] as String?;
          district ??= office['District'] as String?;
        }
      }

      if (state == null || district == null) {
        return const ErrorResult(
          ValidationFailure('No address found for this PIN code.'),
        );
      }

      return Success(
        PincodeResult(
          state: state,
          district: district,
          localities: localities,
        ),
      );
    } catch (_) {
      return const ErrorResult(
        NetworkFailure('Could not fetch address. Check your connection.'),
      );
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }
}
