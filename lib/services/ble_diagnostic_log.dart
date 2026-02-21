import 'package:flutter/foundation.dart';

/// A single timestamped BLE diagnostic event
class BleLogEntry {
  final DateTime timestamp;
  final String event;
  final String? details;

  BleLogEntry({
    required this.timestamp,
    required this.event,
    this.details,
  });

  @override
  String toString() {
    final ts = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
    return details != null ? '[$ts] $event: $details' : '[$ts] $event';
  }
}

/// Lightweight circular buffer log for BLE diagnostic events.
/// Keeps the most recent [maxEntries] events in memory.
class BleDiagnosticLog {
  final int maxEntries;
  final List<BleLogEntry> _entries = [];

  BleDiagnosticLog({this.maxEntries = 100});

  /// All current log entries (oldest first)
  List<BleLogEntry> get entries => List.unmodifiable(_entries);

  /// Number of entries currently stored
  int get length => _entries.length;

  /// Log a BLE event with optional details
  void log(String event, {String? details}) {
    final entry = BleLogEntry(
      timestamp: DateTime.now(),
      event: event,
      details: details,
    );

    _entries.add(entry);

    // Evict oldest entries when buffer is full
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }

    debugPrint('BLE: $entry');
  }

  /// Clear all log entries
  void clear() {
    _entries.clear();
  }
}
