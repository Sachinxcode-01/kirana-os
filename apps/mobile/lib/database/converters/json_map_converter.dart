import 'dart:convert';
import 'package:drift/drift.dart';

/// Converts between a Dart `Map<String, dynamic>` and a SQLite JSON string.
class JsonMapConverter extends TypeConverter<Map<String, dynamic>, String> {
  const JsonMapConverter();

  @override
  Map<String, dynamic> fromSql(String fromDb) {
    if (fromDb.isEmpty) return {};
    try {
      return json.decode(fromDb) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  String toSql(Map<String, dynamic> value) {
    return json.encode(value);
  }
}
