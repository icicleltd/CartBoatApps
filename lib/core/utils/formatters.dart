import 'package:intl/intl.dart';

import '../config/env.dart';

final _money = NumberFormat('#,##0', 'en_US');
final _moneyPrecise = NumberFormat('#,##0.00', 'en_US');

/// `৳28,990` — whole taka unless the amount has paisa.
String money(num value) {
  final hasFraction = value % 1 != 0;
  return '${Env.currencySymbol}${hasFraction ? _moneyPrecise.format(value) : _money.format(value)}';
}

String compactCount(int n) => NumberFormat.compact().format(n);

String shortDate(DateTime d) => DateFormat('d MMM yyyy').format(d.toLocal());

String dateTime(DateTime d) => DateFormat('d MMM yyyy, h:mm a').format(d.toLocal());

String relativeTime(DateTime d) {
  final diff = DateTime.now().difference(d.toLocal());
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return shortDate(d);
}

String titleCase(String s) {
  final cleaned = s.replaceAll(RegExp(r'[_\-]+'), ' ').trim().toLowerCase();
  if (cleaned.isEmpty) return s;
  return cleaned.split(RegExp(r'\s+')).map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
}

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
