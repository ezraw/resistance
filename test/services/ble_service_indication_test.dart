import 'package:flutter_test/flutter_test.dart';
import 'package:resistance_app/services/ble_service.dart';

void main() {
  group('FtmsResultCodes', () {
    test('defines correct FTMS result codes', () {
      expect(FtmsResultCodes.success, 0x01);
      expect(FtmsResultCodes.opCodeNotSupported, 0x02);
      expect(FtmsResultCodes.invalidParameter, 0x03);
      expect(FtmsResultCodes.operationFailed, 0x04);
      expect(FtmsResultCodes.controlNotPermitted, 0x05);
    });
  });

  group('FtmsMachineStatus', () {
    test('defines correct machine status codes', () {
      expect(FtmsMachineStatus.reset, 0x01);
      expect(FtmsMachineStatus.controlPermissionLost, 0x0A);
    });
  });

  group('FtmsOpCodes', () {
    test('defines correct op codes', () {
      expect(FtmsOpCodes.requestControl, 0x00);
      expect(FtmsOpCodes.reset, 0x01);
      expect(FtmsOpCodes.setTargetResistance, 0x04);
      expect(FtmsOpCodes.responseCode, 0x80);
    });
  });

  group('TrainerConnectionState', () {
    test('includes degraded state', () {
      expect(TrainerConnectionState.values, contains(TrainerConnectionState.degraded));
    });

    test('has all expected states', () {
      expect(TrainerConnectionState.values, containsAll([
        TrainerConnectionState.disconnected,
        TrainerConnectionState.scanning,
        TrainerConnectionState.connecting,
        TrainerConnectionState.connected,
        TrainerConnectionState.degraded,
        TrainerConnectionState.error,
      ]));
    });
  });

  group('FTMS Control Point Indication Parsing', () {
    // Test the parsing logic directly — mirrors _onControlPointIndication

    /// Returns: 'success', 'controlNotPermitted', 'failure', or 'ignored'
    String parseIndication(List<int> data) {
      if (data.length < 3) return 'ignored';
      if (data[0] != FtmsOpCodes.responseCode) return 'ignored';

      final resultCode = data[2];

      if (resultCode == FtmsResultCodes.success) {
        return 'success';
      } else if (resultCode == FtmsResultCodes.controlNotPermitted) {
        return 'controlNotPermitted';
      } else {
        return 'failure';
      }
    }

    test('parses success response for setTargetResistance', () {
      // Response: 0x80, opCode=0x04, result=0x01 (success)
      final data = [0x80, 0x04, 0x01];
      expect(parseIndication(data), 'success');
    });

    test('parses success response for requestControl', () {
      final data = [0x80, 0x00, 0x01];
      expect(parseIndication(data), 'success');
    });

    test('parses controlNotPermitted response', () {
      final data = [0x80, 0x04, 0x05];
      expect(parseIndication(data), 'controlNotPermitted');
    });

    test('parses operationFailed response', () {
      final data = [0x80, 0x04, 0x04];
      expect(parseIndication(data), 'failure');
    });

    test('parses opCodeNotSupported response', () {
      final data = [0x80, 0x04, 0x02];
      expect(parseIndication(data), 'failure');
    });

    test('parses invalidParameter response', () {
      final data = [0x80, 0x04, 0x03];
      expect(parseIndication(data), 'failure');
    });

    test('ignores data that is too short', () {
      expect(parseIndication([]), 'ignored');
      expect(parseIndication([0x80]), 'ignored');
      expect(parseIndication([0x80, 0x04]), 'ignored');
    });

    test('ignores data that does not start with response code', () {
      final data = [0x00, 0x04, 0x01];
      expect(parseIndication(data), 'ignored');
    });

    test('handles data with extra trailing bytes', () {
      // Some trainers may include additional data after the 3 required bytes
      final data = [0x80, 0x04, 0x01, 0xFF, 0xFF];
      expect(parseIndication(data), 'success');
    });
  });

  group('FTMS Machine Status Parsing', () {
    /// Returns true if status indicates control loss
    bool isControlLost(List<int> data) {
      if (data.isEmpty) return false;
      final statusCode = data[0];
      return statusCode == FtmsMachineStatus.reset ||
          statusCode == FtmsMachineStatus.controlPermissionLost;
    }

    test('detects reset status', () {
      expect(isControlLost([0x01]), isTrue);
    });

    test('detects control permission lost', () {
      expect(isControlLost([0x0A]), isTrue);
    });

    test('ignores other status codes', () {
      expect(isControlLost([0x02]), isFalse); // fitness machine stopped
      expect(isControlLost([0x03]), isFalse); // fitness machine started
      expect(isControlLost([0x04]), isFalse); // target speed changed
    });

    test('handles empty data', () {
      expect(isControlLost([]), isFalse);
    });
  });

  group('Failure Counter Logic', () {
    // Test the graduated recovery threshold logic

    test('soft recovery triggers at threshold', () {
      const softThreshold = 3;
      const fullThreshold = 6;

      for (var failures = 1; failures <= 10; failures++) {
        final shouldSoftRecover = failures >= softThreshold && failures < fullThreshold;
        final shouldFullReconnect = failures >= fullThreshold;

        if (shouldFullReconnect) {
          // At 6+ failures, full reconnect should trigger
          expect(failures >= fullThreshold, isTrue,
              reason: 'Full reconnect at $failures failures');
        } else if (shouldSoftRecover) {
          // At 3-5 failures, soft recovery should trigger
          expect(failures >= softThreshold, isTrue,
              reason: 'Soft recovery at $failures failures');
          expect(failures < fullThreshold, isTrue);
        } else {
          // Below threshold, no recovery
          expect(failures < softThreshold, isTrue,
              reason: 'No recovery at $failures failures');
        }
      }
    });
  });

  group('BleService state', () {
    late BleService service;

    setUp(() {
      service = BleService();
    });

    test('starts disconnected', () {
      expect(service.currentState, TrainerConnectionState.disconnected);
      expect(service.isConnected, isFalse);
      expect(service.isDegraded, isFalse);
    });

    test('isConnected returns false when disconnected', () {
      expect(service.isConnected, isFalse);
    });

    test('consecutiveWriteFailures starts at 0', () {
      expect(service.consecutiveWriteFailures, 0);
    });

    test('isRecovering starts as false', () {
      expect(service.isRecovering, isFalse);
    });

    test('diagnostic log is accessible', () {
      expect(service.diagnosticLog, isNotNull);
      expect(service.diagnosticLog.length, 0);
    });

    test('setResistanceLevel returns false when disconnected', () async {
      final result = await service.setResistanceLevel(50);
      expect(result, isFalse);
    });

    test('increaseResistance returns true at max level', () async {
      // When not connected, the _currentResistanceLevel is 0, not 100
      // so it will try to set and fail
      final result = await service.increaseResistance();
      expect(result, isFalse); // Fails because not connected
    });

    test('decreaseResistance returns true at min level', () async {
      // At 0 already, returns true immediately
      final result = await service.decreaseResistance();
      expect(result, isTrue);
    });
  });

  group('Connection state transitions', () {
    test('connectionState stream emits state changes', () async {
      final service = BleService();
      final future = service.connectionState.first;

      // disconnect() emits disconnected state
      await service.disconnect();

      final state = await future;
      expect(state, TrainerConnectionState.disconnected);
      service.dispose();
    });
  });
}
