import 'dart:convert';

import 'package:first_mqtt_app/services/mqtt.dart';
import 'package:first_mqtt_app/services/time_service.dart';
import 'package:flutter/material.dart';

class TopicConfig {
  final String title;
  final String suffix; // topic is esp/{mac}/{suffix}
  final int qos;
  final IconData icon;
  const TopicConfig(this.title, this.suffix, this.qos, this.icon);
}

class MessageEntry {
  final String payload;
  final int? seqId;
  final int? latencyMs;
  final DateTime receivedAt;
  const MessageEntry(this.payload, this.seqId, this.latencyMs, this.receivedAt);
}

class TopicStats extends ChangeNotifier {
  final TopicConfig config;
  TopicStats(this.config);

  static const int maxHistory = 100;

  final List<MessageEntry> messages = []; // newest first
  final Map<int, int> latencyBySeq =
      {}; // seq_id -> latency (ms), for export later
  final Set<int> _seen = {};

  int totalReceived = 0; // includes duplicates and messages without seq_id
  int duplicates = 0;
  int outOfOrder = 0;
  int? firstSeq;
  int? lastSeq;
  int? highestSeq;

  int? minLatency;
  int? maxLatency;
  int _latencySum = 0;
  int _latencyCount = 0;

  double? get avgLatency =>
      _latencyCount == 0 ? null : _latencySum / _latencyCount;

  int get uniqueReceived => _seen.length;
  int get expected => (firstSeq == null || highestSeq == null)
      ? 0
      : highestSeq! - firstSeq! + 1;
  int get lost => expected - uniqueReceived;
  double get lossPercent => expected == 0 ? 0 : lost / expected * 100;

  /// Missing seq_ids between the first and highest seen (capped for display).
  List<int> missingSeqIds({int limit = 50}) {
    final out = <int>[];
    if (firstSeq == null || highestSeq == null) return out;
    for (var i = firstSeq!; i <= highestSeq! && out.length < limit; i++) {
      if (!_seen.contains(i)) out.add(i);
    }
    return out;
  }

  void add(MqttIncoming msg) {
    totalReceived++;

    int? seq;
    int? latency;
    try {
      final json = jsonDecode(msg.payload);
      if (json is Map<String, dynamic>) {
        seq = (json['seq_id'] as num?)?.toInt();
        final ra = json['recorded_at'];
        if (ra is String && TimeService.instance.isSynced) {
          final t = DateTime.tryParse(ra);
          // The ESP32 falls back to 1970 when its own sync failed -> ignore
          if (t != null && t.year > 2000) {
            latency =
                msg.receivedAt.millisecondsSinceEpoch -
                t.millisecondsSinceEpoch;
          }
        }
      }
    } catch (_) {
      // payload isn't JSON; still show it in the stream
    }

    var isDuplicate = false;
    if (seq != null) {
      if (!_seen.add(seq)) {
        isDuplicate = true;
        duplicates++;
      } else {
        if (lastSeq != null && seq < lastSeq!) outOfOrder++;
        lastSeq = seq;
        firstSeq = (firstSeq == null || seq < firstSeq!) ? seq : firstSeq;
        highestSeq = (highestSeq == null || seq > highestSeq!)
            ? seq
            : highestSeq;
      }
    }

    if (latency != null && !isDuplicate) {
      if (seq != null) latencyBySeq[seq] = latency;
      minLatency = (minLatency == null || latency < minLatency!)
          ? latency
          : minLatency;
      maxLatency = (maxLatency == null || latency > maxLatency!)
          ? latency
          : maxLatency;
      _latencySum += latency;
      _latencyCount++;
    }

    messages.insert(0, MessageEntry(msg.payload, seq, latency, msg.receivedAt));
    if (messages.length > maxHistory) messages.removeLast();

    notifyListeners();
  }

  void reset() {
    messages.clear();
    latencyBySeq.clear();
    _seen.clear();
    totalReceived = duplicates = outOfOrder = 0;
    firstSeq = lastSeq = highestSeq = null;
    minLatency = maxLatency = null;
    _latencySum = _latencyCount = 0;
    notifyListeners();
  }
}
