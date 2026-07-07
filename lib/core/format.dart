import 'package:intl/intl.dart';

final _time = DateFormat('h:mm a');
final _day = DateFormat('EEE, MMM d');
final _ngn = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

String formatTime(DateTime dt) => _time.format(dt);

String formatTimeRange(DateTime start, DateTime end) =>
    '${formatTime(start)} – ${formatTime(end)}';

String formatDayLabel(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  if (day == today) return 'Today';
  if (day == today.add(const Duration(days: 1))) return 'Tomorrow';
  return _day.format(dt);
}

String formatNgn(num amount) => _ngn.format(amount);

String initials(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}

/// First name for greetings — a single, clean, capitalised token.
String greetingFirstName(String displayName) {
  final trimmed = displayName.trim();
  if (trimmed.isEmpty) return 'Delegate';

  // Break camelCase (e.g. "JohnDoe" -> "John Doe") then split on separators.
  final spaced =
      trimmed.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
  final parts =
      spaced.split(RegExp(r'[\s._\-]+')).where((p) => p.isNotEmpty).toList();

  var first = (parts.isEmpty ? trimmed : parts.first).replaceAll(RegExp(r'\d'), '');
  if (first.isEmpty) return 'Delegate';

  final capitalised = '${first[0].toUpperCase()}${first.substring(1).toLowerCase()}';
  // Only truncate genuinely unreasonable tokens, and never mid-name if avoidable.
  if (capitalised.length > 18) return '${capitalised.substring(0, 17)}…';
  return capitalised;
}

DateTime? parseIso(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
