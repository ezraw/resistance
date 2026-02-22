import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

/// Minimal reproduction of the debounce logic from _HomeScreenState.
///
/// We extract the scheduling/sending logic into a standalone class so we can
/// unit-test the race condition fix without needing the full widget tree and
/// all its platform-plugin dependencies (BLE, HealthKit, WakeLock, etc.).
class _ResistanceDebounceLogic {
  int currentLevel;
  int pendingLevel = 0;
  bool hasPendingUpdate = false;
  Timer? debounceTimer;

  /// Simulated BLE write function injected by tests.
  final Future<bool> Function(int level) bleWrite;

  /// Called when BLE stream pushes a resistance confirmation.
  final void Function(int level)? onLevelConfirmed;

  _ResistanceDebounceLogic({
    required this.currentLevel,
    required this.bleWrite,
    this.onLevelConfirmed,
  });

  /// Mirrors _HomeScreenState._onResistanceLevelChanged
  void onResistanceLevelChanged(int level) {
    if (hasPendingUpdate) return;
    currentLevel = level;
    onLevelConfirmed?.call(level);
  }

  /// Mirrors _HomeScreenState._increaseResistance
  void increase() {
    if (currentLevel >= 100) return;
    currentLevel = (currentLevel + 5).clamp(0, 100);
    scheduleBleUpdate(currentLevel);
  }

  /// Mirrors _HomeScreenState._decreaseResistance
  void decrease() {
    if (currentLevel <= 0) return;
    currentLevel = (currentLevel - 5).clamp(0, 100);
    scheduleBleUpdate(currentLevel);
  }

  /// Mirrors _HomeScreenState._scheduleBleUpdate
  void scheduleBleUpdate(int level) {
    pendingLevel = level;
    hasPendingUpdate = true;
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 150), () {
      sendBleUpdate(pendingLevel);
    });
  }

  /// Mirrors _HomeScreenState._sendBleUpdate (with the fix applied)
  Future<void> sendBleUpdate(int level) async {
    final success = await bleWrite(level);
    // FIX: Only clear hasPendingUpdate when the completed level matches
    // pendingLevel, so a newer write keeps the flag true.
    if (pendingLevel == level) {
      hasPendingUpdate = false;
    }
    if (!success) {
      // Revert would happen here in the real code
    }
  }

  void dispose() {
    debounceTimer?.cancel();
  }
}

void main() {
  group('Resistance debounce logic', () {
    test('hasPendingUpdate stays true when a newer write is pending', () async {
      // Simulate two overlapping BLE writes where the first completes
      // while the second is still in flight.
      final writeCompleters = <int, Completer<bool>>{};

      final logic = _ResistanceDebounceLogic(
        currentLevel: 50,
        bleWrite: (level) {
          final c = Completer<bool>();
          writeCompleters[level] = c;
          return c.future;
        },
      );

      // First tap: schedule write for level 55
      logic.increase(); // currentLevel = 55
      expect(logic.hasPendingUpdate, isTrue);

      // Fire the debounce timer
      await Future.delayed(const Duration(milliseconds: 200));

      // Write for 55 is now in flight
      expect(writeCompleters.containsKey(55), isTrue);

      // Second tap arrives before write 55 completes
      logic.increase(); // currentLevel = 60, pendingLevel = 60
      expect(logic.pendingLevel, 60);

      // Complete the first write (level 55)
      writeCompleters[55]!.complete(true);
      await Future.delayed(Duration.zero); // Let the future resolve

      // KEY ASSERTION: hasPendingUpdate must still be true because
      // pendingLevel (60) != completed level (55)
      expect(logic.hasPendingUpdate, isTrue);

      // Fire the second debounce timer
      await Future.delayed(const Duration(milliseconds: 200));

      // Complete the second write (level 60)
      expect(writeCompleters.containsKey(60), isTrue);
      writeCompleters[60]!.complete(true);
      await Future.delayed(Duration.zero);

      // Now hasPendingUpdate should be false
      expect(logic.hasPendingUpdate, isFalse);

      logic.dispose();
    });

    test('BLE stream confirmation is ignored while update is pending', () {
      int confirmedLevel = -1;

      final logic = _ResistanceDebounceLogic(
        currentLevel: 50,
        bleWrite: (_) async => true,
        onLevelConfirmed: (level) => confirmedLevel = level,
      );

      // Start a tap sequence
      logic.increase(); // currentLevel = 55
      expect(logic.hasPendingUpdate, isTrue);

      // BLE stream pushes an intermediate value (e.g., 50 from a previous
      // confirmation that just arrived)
      logic.onResistanceLevelChanged(50);

      // The level must NOT revert — the stream event is ignored
      expect(logic.currentLevel, 55);
      expect(confirmedLevel, -1); // onLevelConfirmed was not called

      logic.dispose();
    });

    test('rapid increase taps produce monotonically increasing level', () async {
      final writtenLevels = <int>[];

      final logic = _ResistanceDebounceLogic(
        currentLevel: 20,
        bleWrite: (level) async {
          writtenLevels.add(level);
          return true;
        },
      );

      // Rapid taps: 25, 30, 35, 40
      logic.increase();
      logic.increase();
      logic.increase();
      logic.increase();

      expect(logic.currentLevel, 40);
      expect(logic.pendingLevel, 40);

      // Let debounce fire
      await Future.delayed(const Duration(milliseconds: 200));

      // Only one BLE write should have been sent (the final level)
      expect(writtenLevels, [40]);
      expect(logic.hasPendingUpdate, isFalse);

      logic.dispose();
    });

    test('rapid decrease taps produce monotonically decreasing level', () async {
      final writtenLevels = <int>[];

      final logic = _ResistanceDebounceLogic(
        currentLevel: 40,
        bleWrite: (level) async {
          writtenLevels.add(level);
          return true;
        },
      );

      // Rapid taps: 35, 30, 25, 20
      logic.decrease();
      logic.decrease();
      logic.decrease();
      logic.decrease();

      expect(logic.currentLevel, 20);
      expect(logic.pendingLevel, 20);

      // Let debounce fire
      await Future.delayed(const Duration(milliseconds: 200));

      expect(writtenLevels, [20]);
      expect(logic.hasPendingUpdate, isFalse);

      logic.dispose();
    });

    test('slow taps each send their own BLE write', () async {
      final writtenLevels = <int>[];

      final logic = _ResistanceDebounceLogic(
        currentLevel: 50,
        bleWrite: (level) async {
          writtenLevels.add(level);
          return true;
        },
      );

      // First tap
      logic.increase(); // 55
      await Future.delayed(const Duration(milliseconds: 200));
      expect(writtenLevels, [55]);

      // Second tap after debounce settled
      logic.increase(); // 60
      await Future.delayed(const Duration(milliseconds: 200));
      expect(writtenLevels, [55, 60]);

      expect(logic.hasPendingUpdate, isFalse);

      logic.dispose();
    });

    test('failed BLE write does not clear hasPendingUpdate for newer level', () async {
      final writeCompleters = <int, Completer<bool>>{};

      final logic = _ResistanceDebounceLogic(
        currentLevel: 50,
        bleWrite: (level) {
          final c = Completer<bool>();
          writeCompleters[level] = c;
          return c.future;
        },
      );

      // Tap to 55
      logic.increase();
      await Future.delayed(const Duration(milliseconds: 200));

      // Tap to 60 while write for 55 is in flight
      logic.increase();

      // Fail the first write
      writeCompleters[55]!.complete(false);
      await Future.delayed(Duration.zero);

      // hasPendingUpdate should still be true (60 is pending)
      expect(logic.hasPendingUpdate, isTrue);

      // Let second debounce fire and complete successfully
      await Future.delayed(const Duration(milliseconds: 200));
      writeCompleters[60]!.complete(true);
      await Future.delayed(Duration.zero);

      expect(logic.hasPendingUpdate, isFalse);

      logic.dispose();
    });
  });
}
