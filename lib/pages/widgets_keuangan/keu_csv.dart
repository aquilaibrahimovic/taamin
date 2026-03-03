/// ✅ Standard CSV escaping for exports
String csvEscape(String s) {
  final needsQuotes =
      s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r');
  var out = s.replaceAll('"', '""');
  if (needsQuotes) out = '"$out"';
  return out;
}

/// ✅ Converts rows to a CSV string
String toCsv(List<List<dynamic>> rows) {
  return rows
      .map((r) => r.map((v) => csvEscape(v?.toString() ?? '')).join(','))
      .join('\n');
}

/// ✅ Simple CSV parser for imports
List<List<String>> parseCsvSimple(String content) {
  final lines = content
      .split(RegExp(r'\r?\n'))
      .where((l) => l.trim().isNotEmpty)
      .toList();

  final out = <List<String>>[];
  for (final line in lines) {
    final row = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        row.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    row.add(buf.toString());
    out.add(row);
  }
  return out;
}

/// ✅ Sanitizes strings for safe filenames
String sanitizeForFileName(String s) {
  final trimmed = s.trim().toLowerCase();
  final replaced = trimmed.replaceAll(RegExp(r'\s+'), '-');
  return replaced.replaceAll(RegExp(r'[^a-z0-9\-_]'), '');
}