/// Safe JSON parsing utilities to prevent runtime crashes from malformed API responses.
///
/// All helpers return null-safe values and never throw on bad input.
library;

/// Safely extract a String from JSON, returning [fallback] on any mismatch.
String safeString(
  Map<String, dynamic> json,
  String key, {
  String fallback = '',
}) {
  final value = json[key];
  if (value == null) return fallback;
  return value.toString();
}

/// Safely extract a non-null String — throws if missing (use for required fields).
String requiredString(
  Map<String, dynamic> json,
  String key, {
  String fallback = '',
}) {
  final value = json[key];
  if (value == null) return fallback;
  return value.toString();
}

/// Safely extract an int from JSON. Handles both native ints and string-encoded numbers.
int safeInt(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Safely extract a bool from JSON. Handles strings like 'true'/'false' and 0/1.
bool safeBool(Map<String, dynamic> json, String key, {bool fallback = false}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return fallback;
}

/// Safely extract a double from JSON. Handles strings and ints.
double safeDouble(
  Map<String, dynamic> json,
  String key, {
  double fallback = 0.0,
}) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

/// Safely extract a nullable String.
String? safeStringOrNull(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  return value.toString();
}

/// Safely parse a DateTime from a JSON string field.
/// Returns [fallback] on null or parse failure.
DateTime safeDateTime(
  Map<String, dynamic> json,
  String key, {
  DateTime? fallback,
}) {
  final value = json[key];
  if (value == null) return fallback ?? DateTime.now();
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return fallback ?? DateTime.now();
}

/// Safely parse a nullable DateTime from a JSON string field.
DateTime? safeDateTimeOrNull(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Safely extract a List<String> from JSON.
List<String> safeStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) return [];
  return value.map((e) => e.toString()).toList();
}

/// Safely extract a List of Maps from JSON.
List<Map<String, dynamic>> safeMapList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) return [];
  return value.whereType<Map<String, dynamic>>().toList();
}

/// Safely extract a nested Map from JSON.
Map<String, dynamic>? safeMapOrNull(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
