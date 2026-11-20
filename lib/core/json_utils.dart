import 'dart:convert';

double? asDouble(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? asInt(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

bool? asBool(Object? v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return null;
}

/// Decodes a JSON object, returns null if the payload is not one.
Map<String, dynamic>? decodeJsonObject(String payload) {
  try {
    final j = jsonDecode(payload);
    return j is Map<String, dynamic> ? j : null;
  } catch (_) {
    return null;
  }
}
