import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Connection state for the trainer
enum TrainerConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// BLE Service for communicating with FTMS-compatible trainers
class BleService {
  static const String _lastDeviceKey = 'last_device_id';

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _controlPointCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  final _connectionStateController = StreamController<TrainerConnectionState>.broadcast();
  final _resistanceLevelController = StreamController<int>.broadcast();

  TrainerConnectionState _currentState = TrainerConnectionState.disconnected;
  int _currentResistanceLevel = 5;
  bool _hasControl = false;

  /// Stream of connection state changes
  Stream<TrainerConnectionState> get connectionState => _connectionStateController.stream;

  /// Stream of resistance level changes
  Stream<int> get resistanceLevel => _resistanceLevelController.stream;

  /// Current connection state
  TrainerConnectionState get currentState => _currentState;

  /// Current resistance level (1-10)
  int get currentResistanceLevel => _currentResistanceLevel;

  /// Whether currently connected to a trainer
  bool get isConnected => _currentState == TrainerConnectionState.connected;

  /// Check if Bluetooth is available and on
  Future<bool> isBluetoothAvailable() async {
    if (await FlutterBluePlus.isSupported == false) {
      return false;
    }
    return await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
  }

  /// Start scanning for FTMS devices
  Future<Stream<List<ScanResult>>> startScan() async {
    _updateState(TrainerConnectionState.scanning);

    await FlutterBluePlus.startScan(
      withServices: [FtmsUuids.service],
      timeout: const Duration(seconds: 15),
    );

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

      _updateState(TrainerConnectionState.connected);
      return true;
    } catch (e) {
      print('Connection error: $e');
      _updateState(TrainerConnectionState.error);
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    _hasControl = false;
    _controlPointCharacteristic = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        print('Disconnect error: $e');
      }
      _connectedDevice = null;
    }

    _updateState(TrainerConnectionState.disconnected);
  }

  /// Try to reconnect to the last known device
  Future<bool> tryAutoConnect() async {
    final lastDeviceId = await _getLastDeviceId();
    if (lastDeviceId == null) return false;

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

    await FlutterBluePlus.startScan(
      withServices: [FtmsUuids.service],
      timeout: const Duration(seconds: 10),
    );

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

  /// Set resistance level (1-10)
  Future<bool> setResistanceLevel(int level) async {
    if (!isConnected || _controlPointCharacteristic == null) {
      return false;
    }

    // Clamp level to valid range
    level = level.clamp(1, 10);

    // Request control if we don't have it yet
    if (!_hasControl) {
      final gotControl = await _requestControl();
      if (!gotControl) return false;
    }

    // Convert level (1-10) to FTMS resistance value (10-100)
    // FTMS uses 0.1 resolution, so level 5 = 50 (representing 50%)
    final ftmsValue = level * 10;

    try {
      await _controlPointCharacteristic!.write(
        [FtmsOpCodes.setTargetResistance, ftmsValue],
        withoutResponse: false,
      );

      _currentResistanceLevel = level;
      _resistanceLevelController.add(level);
      return true;
    } catch (e) {
      print('Error setting resistance: $e');
      return false;
    }
  }

  /// Increase resistance by 1 level
  Future<bool> increaseResistance() async {
    if (_currentResistanceLevel >= 10) return true;
    return await setResistanceLevel(_currentResistanceLevel + 1);
  }

  /// Decrease resistance by 1 level
  Future<bool> decreaseResistance() async {
    if (_currentResistanceLevel <= 1) return true;
    return await setResistanceLevel(_currentResistanceLevel - 1);
  }

  /// Clean up resources
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _connectionStateController.close();
    _resistanceLevelController.close();
    disconnect();
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
        print('FTMS service not found');
        return false;
      }

      // Find control point characteristic
      for (final char in ftmsService.characteristics) {
        if (char.uuid == FtmsUuids.controlPoint) {
          _controlPointCharacteristic = char;

          // Enable indications for responses
          if (char.properties.indicate) {
            await char.setNotifyValue(true);
          }
          break;
        }
      }

      if (_controlPointCharacteristic == null) {
        print('Control point characteristic not found');
        return false;
      }

      return true;
    } catch (e) {
      print('Error setting up FTMS: $e');
      return false;
    }
  }

  Future<bool> _requestControl() async {
    if (_controlPointCharacteristic == null) return false;

    try {
      await _controlPointCharacteristic!.write(
        [FtmsOpCodes.requestControl],
        withoutResponse: false,
      );
      _hasControl = true;
      return true;
    } catch (e) {
      print('Error requesting control: $e');
      return false;
    }
  }

  void _handleDisconnection() {
    _hasControl = false;
    _controlPointCharacteristic = null;
    _connectedDevice = null;
    _updateState(TrainerConnectionState.disconnected);
  }

  void _updateState(TrainerConnectionState state) {
    _currentState = state;
    _connectionStateController.add(state);
  }

  Future<void> _saveLastDevice(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDeviceKey, deviceId);
  }

  Future<String?> _getLastDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastDeviceKey);
  }
}
