/// Defensive readers for loosely-typed API payloads.
typedef Json = Map<String, dynamic>;

Json asJson(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Json> asJsonList(Object? v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

String str(Object? v, [String fallback = '']) => v == null ? fallback : v.toString();

String? strOrNull(Object? v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

double numOf(Object? v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

int intOf(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

bool boolOf(Object? v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is String) return v == 'true';
  if (v is num) return v != 0;
  return fallback;
}

DateTime? dateOf(Object? v) => v == null ? null : DateTime.tryParse(v.toString());

/// Returns the first non-null value among [keys] of [json].
Object? pick(Json json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v != null && !(v is String && v.isEmpty)) return v;
  }
  return null;
}

List<String> strList(Object? v) =>
    v is List ? v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() : const [];

/// Only http(s) URLs are loadable — the API sometimes stores `blob:` URLs.
String? usableImageUrl(Object? v) {
  final s = strOrNull(v);
  if (s == null) return null;
  return (s.startsWith('http://') || s.startsWith('https://')) ? s : null;
}
