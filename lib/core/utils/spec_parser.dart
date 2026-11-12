/// Parses the free-form `specification` string sellers enter into ordered
/// key/value rows. Handles both `"Key": "Value",` JSON-ish lines and plain
/// `Key: Value` lines.
List<MapEntry<String, String>> parseSpecifications(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  final rows = <MapEntry<String, String>>[];

  final quoted = RegExp(r'"([^"]+)"\s*:\s*"([^"]*)"');
  final matches = quoted.allMatches(raw).toList();
  if (matches.isNotEmpty) {
    for (final m in matches) {
      rows.add(MapEntry(m.group(1)!.trim(), m.group(2)!.trim()));
    }
    return rows;
  }

  for (final line in raw.split(RegExp(r'[\n;]+'))) {
    final idx = line.indexOf(':');
    if (idx <= 0) continue;
    final key = line.substring(0, idx).replaceAll(RegExp(r'''^[\s"'{,]+|[\s"',]+$'''), '');
    final value = line.substring(idx + 1).replaceAll(RegExp(r'''^[\s"']+|[\s"',}]+$'''), '');
    if (key.isNotEmpty && value.isNotEmpty) rows.add(MapEntry(key, value));
  }
  return rows;
}
