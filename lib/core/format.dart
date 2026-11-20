String fmtNum(double? v, {int digits = 1}) =>
    v == null ? '--' : v.toStringAsFixed(digits);

String _two(int n) => n.toString().padLeft(2, '0');

/// HH:mm:ss in local time.
String fmtClock(DateTime t) {
  final l = t.toLocal();
  return '${_two(l.hour)}:${_two(l.minute)}:${_two(l.second)}';
}

/// HH:mm in local time.
String fmtClockShort(DateTime t) {
  final l = t.toLocal();
  return '${_two(l.hour)}:${_two(l.minute)}';
}

/// 75 -> 01:15, 3700 -> 1:01:40
String fmtDuration(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  return h > 0 ? '$h:${_two(m)}:${_two(s)}' : '${_two(m)}:${_two(s)}';
}

/// "3 s ago", "2 min ago", "1 h ago"
String fmtAgo(Duration d) {
  if (d.inSeconds < 5) return 'just now';
  if (d.inSeconds < 60) return '${d.inSeconds} s ago';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  return '${d.inHours} h ago';
}
