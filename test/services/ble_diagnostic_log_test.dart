import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/services/ble_diagnostic_log.dart';

void main() {
  group('BleDiagnosticLog', () {
    late BleDiagnosticLog log;

    setUp(() {
      log = BleDiagnosticLog(maxEntries: 5);
    });

    test('starts empty', () {
      expect(log.length, 0);
      expect(log.entries, isEmpty);
    });

    test('logs a simple event', () {
      log.log('Connected');
      expect(log.length, 1);
      expect(log.entries.first.event, 'Connected');
      expect(log.entries.first.details, isNull);
    });

    test('logs an event with details', () {
      log.log('Write failed', details: 'level=50 error=timeout');
      expect(log.length, 1);
      expect(log.entries.first.event, 'Write failed');
      expect(log.entries.first.details, 'level=50 error=timeout');
    });

    test('stores timestamps', () {
      final before = DateTime.now();
      log.log('Event');
      final after = DateTime.now();

      final entry = log.entries.first;
      expect(entry.timestamp.isAfter(before) || entry.timestamp.isAtSameMomentAs(before), isTrue);
      expect(entry.timestamp.isBefore(after) || entry.timestamp.isAtSameMomentAs(after), isTrue);
    });

    test('evicts oldest entries when buffer is full', () {
      for (var i = 0; i < 7; i++) {
        log.log('Event $i');
      }

      expect(log.length, 5);
      // Oldest two should be evicted
      expect(log.entries.first.event, 'Event 2');
      expect(log.entries.last.event, 'Event 6');
    });

    test('maintains order oldest to newest', () {
      log.log('First');
      log.log('Second');
      log.log('Third');

      expect(log.entries[0].event, 'First');
      expect(log.entries[1].event, 'Second');
      expect(log.entries[2].event, 'Third');
    });

    test('clear removes all entries', () {
      log.log('Event 1');
      log.log('Event 2');
      expect(log.length, 2);

      log.clear();
      expect(log.length, 0);
      expect(log.entries, isEmpty);
    });

    test('entries list is unmodifiable', () {
      log.log('Event');
      expect(
        () => log.entries.add(BleLogEntry(
          timestamp: DateTime.now(),
          event: 'Injected',
        )),
        throwsUnsupportedError,
      );
    });

    test('default maxEntries is 100', () {
      final defaultLog = BleDiagnosticLog();
      for (var i = 0; i < 110; i++) {
        defaultLog.log('Event $i');
      }
      expect(defaultLog.length, 100);
      expect(defaultLog.entries.first.event, 'Event 10');
    });
  });

  group('BleLogEntry', () {
    test('toString without details', () {
      final entry = BleLogEntry(
        timestamp: DateTime(2026, 1, 25, 14, 30, 45, 123),
        event: 'Connected',
      );
      expect(entry.toString(), '[14:30:45.123] Connected');
    });

    test('toString with details', () {
      final entry = BleLogEntry(
        timestamp: DateTime(2026, 1, 25, 9, 5, 3, 7),
        event: 'Write failed',
        details: 'timeout',
      );
      expect(entry.toString(), '[09:05:03.007] Write failed: timeout');
    });
  });
}
