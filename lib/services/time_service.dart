import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ntp/ntp.dart';

class TimeService {
  TimeService._();
  static final TimeService instance = TimeService._();

  static const List<String> servers = ['pool.ntp.org', 'time.nist.gov'];

  int _offsetMs = 0;
  bool _synced = false;
  Timer? _resyncTimer;

  bool get isSynced => _synced;
  int get offsetMs => _offsetMs;

  Future<bool> sync() async {
    for (final server in servers) {
      try {
        _offsetMs = await NTP.getNtpOffset(
          localTime: DateTime.now(),
          lookUpAddress: server,
          timeout: const Duration(seconds: 5),
        );
        _synced = true;
        if (kDebugMode)
          debugPrint('[TIME] Synced with $server, offset $_offsetMs ms');
        return true;
      } catch (e) {
        if (kDebugMode) debugPrint('[TIME] $server failed: $e');
      }
    }
    return _synced;
  }

  /// Re-sync periodically so phone clock drift doesn't skew long tests.
  void startPeriodicSync({Duration every = const Duration(minutes: 10)}) {
    _resyncTimer?.cancel();
    _resyncTimer = Timer.periodic(every, (_) => sync());
  }

  void stopPeriodicSync() => _resyncTimer?.cancel();

  /// NTP-corrected current time in UTC.
  DateTime nowUtc() =>
      DateTime.now().toUtc().add(Duration(milliseconds: _offsetMs));

  /// Same format as the ESP32: 2026-10-09T12:33:47.982Z (millisecond precision).
  static String toIso8601Ms(DateTime t) => DateTime.fromMillisecondsSinceEpoch(
    t.millisecondsSinceEpoch,
    isUtc: true,
  ).toIso8601String();
}
