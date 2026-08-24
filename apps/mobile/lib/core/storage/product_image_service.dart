import 'dart:typed_data';
import '../errors/failure.dart';
import '../errors/result.dart';
import '../utils/app_logger.dart';

/// Service for product image validation, normalization, and secure Supabase Storage paths.
class ProductImageService {
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp'
  ];

  /// Validates file size and MIME extension.
  Result<bool, Failure> validateImage({
    required Uint8List bytes,
    required String fileName,
  }) {
    if (bytes.isEmpty) {
      return const ErrorResult(ValidationFailure('Image data cannot be empty'));
    }

    if (bytes.lengthInBytes > maxFileSizeBytes) {
      return const ErrorResult(
          ValidationFailure('Image size exceeds 5MB limit'));
    }

    final ext = _getExtension(fileName).toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      return ErrorResult(ValidationFailure(
          'Unsupported image format: $ext. Allowed: JPG, PNG, WebP'));
    }

    return const Success(true);
  }

  /// Builds a secure, tenant-scoped storage path: `products/{shopId}/{productId}/{normalizedFilename}`.
  String buildStoragePath({
    required String shopId,
    required String productId,
    required String fileName,
  }) {
    final sanitizedShopId = shopId.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '');
    final sanitizedProductId =
        productId.replaceAll(RegExp(r'[^a-zA-Z0-9\-]'), '');

    final ext = _getExtension(fileName).toLowerCase();
    final baseName = _getBaseNameWithoutExtension(fileName)
        .replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_');
    final uniqueSuffix = DateTime.now().millisecondsSinceEpoch;
    final normalizedFileName = '${baseName}_$uniqueSuffix$ext';

    final path = '$sanitizedShopId/$sanitizedProductId/$normalizedFileName';
    AppLogger.d('Generated product image storage path: $path',
        tag: 'ProductImageService');
    return path;
  }

  static String _getExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex == -1) return '';
    return fileName.substring(dotIndex);
  }

  static String _getBaseNameWithoutExtension(String fileName) {
    final normalized = fileName.replaceAll(r'\', '/');
    final lastSlash = normalized.lastIndexOf('/');
    final name =
        lastSlash == -1 ? normalized : normalized.substring(lastSlash + 1);
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1) return name;
    return name.substring(0, dotIndex);
  }
}
