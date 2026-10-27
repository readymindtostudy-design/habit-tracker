import 'package:flutter/material.dart';

const List<String> monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const List<String> weekdaysShort = [
  'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
];
const List<String> weekdayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

String two(int n) => n < 10 ? '0$n' : '$n';

String dateKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

String todayKey() => dateKey(DateTime.now());

DateTime parseKey(String k) {
  final parts = k.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// Formats a number the way the app shows progress values (drops trailing .0).
String fmtNumber(double v) {
  if ((v - v.roundToDouble()).abs() < 0.0001) return v.round().toString();
  return ((v * 100).round() / 100).toString();
}

/// "07:30" -> "7:30 AM"
String fmtTime(String t) {
  final parts = t.split(':');
  int h = int.parse(parts[0]);
  final int m = int.parse(parts[1]);
  final String ap = h >= 12 ? 'PM' : 'AM';
  h = h % 12;
  if (h == 0) h = 12;
  return '$h:${two(m)} $ap';
}

/// Minutes -> "25m" or "1h 05m"
String fmtMinutes(double m) {
  final int r = m.round();
  if (r < 60) return '${r}m';
  return '${r ~/ 60}h ${two(r % 60)}m';
}

String ord(int n) {
  final int v = n % 100;
  if (v >= 11 && v <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}

String dayLabel(String k) {
  if (k == todayKey()) return 'Today';
  final d = parseKey(k);
  return '${weekdaysShort[d.weekday % 7]} ${d.day} ${monthsShort[d.month - 1]}';
}

Color hexColor(String hex) {
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

Color tint(String hex, double alpha) => hexColor(hex).withValues(alpha: alpha);

String greeting() {
  final int h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

/// Short, sortable, reasonably unique id. Good enough for local-only data.
String newId() {
  final int now = DateTime.now().microsecondsSinceEpoch;
  return now.toRadixString(36);
}
