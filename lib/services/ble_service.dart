import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'ble_diagnostic_log.dart';

/// FTMS (Fitness Machine Service) UUIDs
class FtmsUuids {
  static final Guid service = Guid('00001826-0000-1000-8000-00805f9b34fb');
  static final Guid controlPoint = Guid('00002ad9-0000-1000-8000-00805f9b34fb');
  static final Guid resistanceRange = Guid('00002ad6-0000-1000-8000-00805f9b34fb');
  static final Guid status = Guid('00002ada-0000-1000-8000-00805f9b34fb');
}

/// FTMS Control Point Op Codes
class FtmsOpCodes {
  static const int requestControl = 0x00;
  static const int reset = 0x01;
  static const int setTargetResistance = 0x04;
  static const int responseCode = 0x80;
}

/// FTMS Control Point Result Codes
class FtmsResultCodes {
  static const int success = 0x01;
  static const int opCodeNotSupported = 0x02;
  static const int invalidParameter = 0x03;
  static const int operationFailed = 0x04;
  static const int controlNotPermitted = 0x05;
}

/// FTMS Machine Status codes
class FtmsMachineStatus {
  static const int reset = 0x01;
  static const int controlPermissionLost = 0x0A;
}

/// Connection state for the trainer
enum TrainerConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  degraded,
  error,
}

/// BLE Service for communicating with FTMS-compatible trainers
class BleService {
  static const String _lastDeviceKey = 'last_device_id';
  static const int _softRecoveryThreshold = 3;
  static const int _fullReconnectThreshold = 6;
  static const Duration _healthCheckInterval = Duration(seconds: 30);
  static const Duration _healthCheckTimeout = Duration(seconds: 60);

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _controlPointCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _indicationSubscription;
  StreamSubscription<List<int>>? _statusSubscription;
  Timer? _healthCheckTimer;

  final _connectionStateController = StreamController<TrainerConnectionState>.broadcast();
  final _resistanceLevelController = StreamController<int>.broadcast();

  TrainerConnectionState _currentState = TrainerConnectionState.disconnected;
  int _currentResistanceLevel = 0;
  bool _hasControl = false;

  // Failure tracking
  int _consecutiveWriteFailures = 0;
  DateTime? _lastSuccessfulCommand;
  bool _isRecovering = false;

  /// Diagnostic log for BLE events
  final BleDiagnosticLog diagnosticLog = BleDiagnosticLog();

  /// Stream of connection state changes
  Stream<TrainerConnectionState> get connectionState => _connectionStateController.stream;

  /// Stream of resistance level changes
  Stream<int> get resistanceLevel => _resistanceLevelController.stream;

  /// Current connection state
  TrainerConnectionState get currentState => _currentState;

  /// Current resistance level (0-100)
  int get currentResistanceLevel => _currentResistanceLevel;

  /// Whether currently connected to a trainer (includes degraded state)
  bool get isConnected =>
      _currentState == TrainerConnectionState.connected ||
      _currentState == TrainerConnectionState.degraded;

  /// Whether the connection is in a degraded state
  bool get isDegraded => _currentState == TrainerConnectionState.degraded;

  /// Number of consecutive write failures (exposed for testing)
  @visibleForTesting
  int get consecutiveWriteFailures => _consecutiveWriteFailures;

  /// Whether recovery is in progress (exposed for testing)
  @visibleForTesting
  bool get isRecovering => _isRecovering;

  /// Check if Bluetooth is available and on
  Future<bool> isBluetoothAvailable() async {
    if (await FlutterBluePlus.isSupported == false) {
      return false;
    }
    return await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
  }

  /// Start scanning for FTMS devices
  Future<Stream<List<ScanResult>>> startScan() async {
    // Wait for Bluetooth to be ready (up to 5 seconds)
    try {
      await FlutterBluePlus.adapterState
          .where((state) => state == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Bluetooth not ready: $e');
      _updateState(TrainerConnectionState.error);
      return const Stream.empty();
    }

    _updateState(TrainerConnectionState.scanning);

    try {
      await FlutterBluePlus.startScan(
        withServices: [FtmsUuids.service],
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint('Scan failed: $e');
      _updateState(TrainerConnectionState.error);
    }

    return FlutterBluePlus.scanResults;
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    if (_currentState == TrainerConnectionState.scanning) {
      _updateState(TrainerConnectionState.disconnected);
    }
  }

  /// Connect to a specific device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _updateState(TrainerConnectionState.connecting);
      await stopScan();

      diagnosticLog.log('Connecting', details: device.remoteId.str);

      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      // Listen for disconnection
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // Discover services and set up FTMS
      final success = await _setupFtms(device);
      if (!success) {
        await disconnect();
        return false;
      }

      // Save device ID for auto-reconnect
      await _saveLastDevice(device.remoteId.str);

      // Reset failure tracking on fresh connection
      _consecutiveWriteFailures = 0;
      _lastSuccessfulCommand = DateTime.now();
      _isRecovering = false;

      _updateState(TrainerConnectionState.connected);
      diagnosticLog.log('Connected', details: device.remoteId.str);

      // Start health check timer
      _startHealthCheck();

      // Auto-set resistance to 0% on connection
      await setResistanceLevel(0);

      return true;
    } catch (e) {
      debugPrint('Connection error: $e');
      diagnosticLog.log('Connection error', details: '$e');
      _updateState(TrainerConnectionState.error);
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    diagnosticLog.log('Disconnecting');
    _hasControl = false;
    _controlPointCharacteristic = null;
    _consecutiveWriteFailures = 0;
    _isRecovering = false;
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    await _indicationSubscription?.cancel();
    _indicationSubscription = null;
    await _statusSubscription?.cancel();
    _statusSubscription = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        debugPrint('Disconnect error: $e');
      }
      _connectedDevice = null;
    }

    _updateState(TrainerConnectionState.disconnected);
  }

  /// Try to reconnect to the last known device
  Future<bool> tryAutoConnect() async {
    final lastDeviceId = await _getLastDeviceId();
    if (lastDeviceId == null) return false;

    // Wait for Bluetooth to be ready (up to 5 seconds)
    try {
      await FlutterBluePlus.adapterState
          .where((state) => state == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Bluetooth not ready for auto-connect: $e');
      return false;
    }

    _updateState(TrainerConnectionState.scanning);

    // Scan for the specific device
    Completer<BluetoothDevice?> deviceCompleter = Completer();

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        if (result.device.remoteId.str == lastDeviceId) {
          if (!deviceCompleter.isCompleted) {
            deviceCompleter.complete(result.device);
          }
          break;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(
        withServices: [FtmsUuids.service],
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('Auto-connect scan failed: $e');
      _updateState(TrainerConnectionState.disconnected);
      return false;
    }

    // Wait for device or timeout
    final device = await deviceCompleter.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );

    await _scanSubscription?.cancel();
    await FlutterBluePlus.stopScan();

    if (device != null) {
      return await connectToDevice(device);
    }

    _updateState(TrainerConnectionState.disconnected);
    return false;
  }

  /// Set resistance level (0-100)
  Future<bool> setResistanceLevel(int level) async {
    if (!isConnected || _controlPointCharacteristic == null) {
      return false;
    }

    // Don't send commands during recovery
    if (_isRecovering) {
      diagnosticLog.log('Write skipped', details: 'Recovery in progress');
      return false;
    }

    // Clamp level to valid range
    level = level.clamp(0, 100);

    // Request control if we don't have it yet
    if (!_hasControl) {
      final gotControl = await _requestControl();
      if (!gotControl) return false;
    }

    // FTMS uses 0-100 directly (0.1 resolution, so 50 = 50%)
    final ftmsValue = level;

    try {
      await _controlPointCharacteristic!.write(
        [FtmsOpCodes.setTargetResistance, ftmsValue],
        withoutResponse: false,
      );

      _currentResistanceLevel = level;
      _resistanceLevelController.add(level);
      return true;
    } catch (e) {
      debugPrint('Error setting resistance: $e');
      diagnosticLog.log('Write exception', details: 'level=$level error=$e');
      _onWriteFailure();
      return false;
    }
  }

  /// Increase resistance by 5%
  Future<bool> increaseResistance() async {
    if (_currentResistanceLevel >= 100) return true;
    return await setResistanceLevel(_currentResistanceLevel + 5);
  }

  /// Decrease resistance by 5%
  Future<bool> decreaseResistance() async {
    if (_currentResistanceLevel <= 0) return true;
    return await setResistanceLevel(_currentResistanceLevel - 5);
  }

  /// Clean up resources
  void dispose() {
    _healthCheckTimer?.cancel();
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _indicationSubscription?.cancel();
    _statusSubscription?.cancel();
    // Disconnect before closing streams to avoid adding events after close
    _hasControl = false;
    _controlPointCharacteristic = null;
    _connectedDevice?.disconnect();
    _connectedDevice = null;
    _connectionStateController.close();
    _resistanceLevelController.close();
  }

  // Private methods

  Future<bool> _setupFtms(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();

      // Find FTMS service
      BluetoothService? ftmsService;
      for (final service in services) {
        if (service.uuid == FtmsUuids.service) {
          ftmsService = service;
          break;
        }
      }

      if (ftmsService == null) {
        debugPrint('FTMS service not found');
        diagnosticLog.log('FTMS setup failed', details: 'Service not found');
        return false;
      }

      // Find and subscribe to characteristics
      for (final char in ftmsService.characteristics) {
        if (char.uuid == FtmsUuids.controlPoint) {
          _controlPointCharacteristic = char;

          // Enable indications and subscribe for responses
          if (char.properties.indicate) {
            await char.setNotifyValue(true);
            _indicationSubscription = char.lastValueStream.listen(_onControlPointIndication);
            diagnosticLog.log('FTMS indications subscribed');
          }
        } else if (char.uuid == FtmsUuids.status) {
          // Subscribe to Machine Status characteristic
          if (char.properties.notify || char.properties.indicate) {
            await char.setNotifyValue(true);
            _statusSubscription = char.lastValueStream.listen(_onMachineStatus);
            diagnosticLog.log('FTMS machine status subscribed');
          }
        }
      }

      if (_controlPointCharacteristic == null) {
        debugPrint('Control point characteristic not found');
        diagnosticLog.log('FTMS setup failed', details: 'Control point not found');
        return false;
      }

      diagnosticLog.log('FTMS setup complete');
      return true;
    } catch (e) {
      debugPrint('Error setting up FTMS: $e');
      diagnosticLog.log('FTMS setup error', details: '$e');
      return false;
    }
  }

  /// Handle FTMS Control Point indication responses
  /// Format: byte 0 = 0x80 (response code), byte 1 = request op code, byte 2 = result code
  void _onControlPointIndication(List<int> data) {
    if (data.length < 3) return;
    if (data[0] != FtmsOpCodes.responseCode) return;

    final requestOpCode = data[1];
    final resultCode = data[2];

    diagnosticLog.log('Indication received',
        details: 'opCode=0x${requestOpCode.toRadixString(16)} result=0x${resultCode.toRadixString(16)}');

    if (resultCode == FtmsResultCodes.success) {
      _onCommandSuccess();
    } else if (resultCode == FtmsResultCodes.controlNotPermitted) {
      diagnosticLog.log('Control not permitted', details: 'Will re-request on next command');
      _hasControl = false;
      _onWriteFailure();
    } else {
      diagnosticLog.log('Command failed',
          details: 'opCode=0x${requestOpCode.toRadixString(16)} result=0x${resultCode.toRadixString(16)}');
      _onWriteFailure();
    }
  }

  /// Handle FTMS Machine Status notifications
  void _onMachineStatus(List<int> data) {
    if (data.isEmpty) return;

    final statusCode = data[0];
    diagnosticLog.log('Machine status', details: '0x${statusCode.toRadixString(16)}');

    if (statusCode == FtmsMachineStatus.reset ||
        statusCode == FtmsMachineStatus.controlPermissionLost) {
      diagnosticLog.log('Control lost via machine status',
          details: 'status=0x${statusCode.toRadixString(16)}');
      _hasControl = false;
    }
  }

  void _onCommandSuccess() {
    _consecutiveWriteFailures = 0;
    _lastSuccessfulCommand = DateTime.now();

    // Recover from degraded state
    if (_currentState == TrainerConnectionState.degraded) {
      diagnosticLog.log('Recovered from degraded state');
      _isRecovering = false;
      _updateState(TrainerConnectionState.connected);
    }
  }

  void _onWriteFailure() {
    _consecutiveWriteFailures++;
    diagnosticLog.log('Write failure',
        details: 'consecutive=$_consecutiveWriteFailures');

    if (_consecutiveWriteFailures >= _fullReconnectThreshold) {
      _attemptFullReconnect();
    } else if (_consecutiveWriteFailures >= _softRecoveryThreshold &&
        _currentState != TrainerConnectionState.degraded) {
      _attemptSoftRecovery();
    }
  }

  Future<void> _attemptSoftRecovery() async {
    if (_isRecovering) return;
    _isRecovering = true;

    diagnosticLog.log('Soft recovery started');
    _updateState(TrainerConnectionState.degraded);

    // Reset control and re-request
    _hasControl = false;
    final gotControl = await _requestControl();

    if (gotControl) {
      // Resend current resistance level as a probe
      diagnosticLog.log('Soft recovery', details: 'Resending resistance=$_currentResistanceLevel');
      try {
        await _controlPointCharacteristic!.write(
          [FtmsOpCodes.setTargetResistance, _currentResistanceLevel],
          withoutResponse: false,
        );
      } catch (e) {
        diagnosticLog.log('Soft recovery write failed', details: '$e');
      }
    }

    _isRecovering = false;
  }

  Future<void> _attemptFullReconnect() async {
    if (_isRecovering) return;
    _isRecovering = true;

    diagnosticLog.log('Full reconnect started',
        details: 'failures=$_consecutiveWriteFailures');
    _updateState(TrainerConnectionState.degraded);

    // Disconnect and try auto-connect
    final savedLevel = _currentResistanceLevel;
    await disconnect();

    final reconnected = await tryAutoConnect();
    if (reconnected) {
      diagnosticLog.log('Full reconnect succeeded');
      // Restore previous resistance level
      await setResistanceLevel(savedLevel);
    } else {
      diagnosticLog.log('Full reconnect failed');
    }
    // _isRecovering is reset by disconnect() or connectToDevice()
  }

  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) {
      _performHealthCheck();
    });
  }

  void _performHealthCheck() {
    if (!isConnected || _isRecovering) return;

    final lastCmd = _lastSuccessfulCommand;
    if (lastCmd != null &&
        DateTime.now().difference(lastCmd) > _healthCheckTimeout) {
      diagnosticLog.log('Health check',
          details: 'No successful command in ${_healthCheckTimeout.inSeconds}s, probing');
      _hasControl = false;
      // Resend current resistance as a probe
      setResistanceLevel(_currentResistanceLevel);
    }
  }

  Future<bool> _requestControl() async {
    if (_controlPointCharacteristic == null) return false;

    try {
      diagnosticLog.log('Requesting control');
      await _controlPointCharacteristic!.write(
        [FtmsOpCodes.requestControl],
        withoutResponse: false,
      );
      _hasControl = true;
      diagnosticLog.log('Control granted');
      return true;
    } catch (e) {
      debugPrint('Error requesting control: $e');
      diagnosticLog.log('Control request failed', details: '$e');
      return false;
    }
  }

  void _handleDisconnection() {
    diagnosticLog.log('Disconnection detected');
    _hasControl = false;
    _controlPointCharacteristic = null;
    _connectedDevice = null;
    _consecutiveWriteFailures = 0;
    _isRecovering = false;
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _indicationSubscription?.cancel();
    _indicationSubscription = null;
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _updateState(TrainerConnectionState.disconnected);
  }

  void _updateState(TrainerConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  Future<void> _saveLastDevice(String deviceId) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: _lastDeviceKey, value: deviceId);
  }

  Future<String?> _getLastDeviceId() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: _lastDeviceKey);
  }
}
