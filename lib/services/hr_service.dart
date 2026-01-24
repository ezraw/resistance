import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Heart Rate Service UUIDs (Bluetooth SIG standard)
class HrUuids {
  static final Guid service = Guid('0000180d-0000-1000-8000-00805f9b34fb');
  static final Guid measurement = Guid('00002a37-0000-1000-8000-00805f9b34fb');
}

/// Connection state for heart rate monitor
enum HrConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// Service for communicating with BLE heart rate monitors
class HrService {
  static const String _lastDeviceKey = 'last_hr_device_id';

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _hrMeasurementCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _hrNotificationSubscription;

  final _connectionStateController = StreamController<HrConnectionState>.broadcast();
  final _heartRateController = StreamController<int>.broadcast();

  HrConnectionState _currentState = HrConnectionState.disconnected;
  int _currentHeartRate = 0;

  /// Stream of connection state changes
  Stream<HrConnectionState> get connectionState => _connectionStateController.stream;

  /// Stream of heart rate values
  Stream<int> get heartRate => _heartRateController.stream;

  /// Current connection state
  HrConnectionState get currentState => _currentState;

  /// Current heart rate (0 if not connected)
  int get currentHeartRate => _currentHeartRate;

  /// Whether currently connected to an HR monitor
  bool get isConnected => _currentState == HrConnectionState.connected;

  /// Start scanning for HR monitors
  Future<Stream<List<ScanResult>>> startScan() async {
    // Wait for Bluetooth to be ready (up to 5 seconds)
    try {
      await FlutterBluePlus.adapterState
          .where((state) => state == BluetoothAdapterState.on)
          .first
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      print('Bluetooth not ready for HR scan: $e');
      _updateState(HrConnectionState.error);
      return const Stream.empty();
    }

    _updateState(HrConnectionState.scanning);

    try {
      await FlutterBluePlus.startScan(
        withServices: [HrUuids.service],
        timeout: const Duration(seconds: 15),
      );
    } catch (e) {
      print('HR scan failed: $e');
      _updateState(HrConnectionState.error);
    }

    return FlutterBluePlus.scanResults;
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    if (_currentState == HrConnectionState.scanning) {
      _updateState(HrConnectionState.disconnected);
    }
  }

  /// Connect to a specific HR monitor
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _updateState(HrConnectionState.connecting);
      await stopScan();

      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      // Listen for disconnection
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // Discover services and set up HR measurement
      final success = await _setupHrMeasurement(device);
      if (!success) {
        await disconnect();
        return false;
      }

      // Save device ID for auto-reconnect
      await _saveLastDevice(device.remoteId.str);

      _updateState(HrConnectionState.connected);
      return true;
    } catch (e) {
      print('HR connection error: $e');
      _updateState(HrConnectionState.error);
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    _hrNotificationSubscription?.cancel();
    _hrNotificationSubscription = null;
    _hrMeasurementCharacteristic = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (e) {
        print('HR disconnect error: $e');
      }
      _connectedDevice = null;
    }

    _currentHeartRate = 0;
    _heartRateController.add(0);
    _updateState(HrConnectionState.disconnected);
  }

  /// Try to reconnect to the last known HR device
  Future<bool> tryAutoConnect() async {
    final lastDeviceId = await _getLastDeviceId();
    if (lastDeviceId == null) return false;

    _updateState(HrConnectionState.scanning);

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
      withServices: [HrUuids.service],
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

    _updateState(HrConnectionState.disconnected);
    return false;
  }

  /// Clean up resources
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _hrNotificationSubscription?.cancel();
    _connectionStateController.close();
    _heartRateController.close();
    disconnect();
  }

  // Private methods

  Future<bool> _setupHrMeasurement(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();

      // Find Heart Rate service
      BluetoothService? hrService;
      for (final service in services) {
        if (service.uuid == HrUuids.service) {
          hrService = service;
          break;
        }
      }

      if (hrService == null) {
        print('Heart Rate service not found');
        return false;
      }

      // Find HR Measurement characteristic
      for (final char in hrService.characteristics) {
        if (char.uuid == HrUuids.measurement) {
          _hrMeasurementCharacteristic = char;

          // Enable notifications
          if (char.properties.notify) {
            await char.setNotifyValue(true);
            _hrNotificationSubscription = char.lastValueStream.listen(_onHrData);
          }
          break;
        }
      }

      if (_hrMeasurementCharacteristic == null) {
        print('HR Measurement characteristic not found');
        return false;
      }

      return true;
    } catch (e) {
      print('Error setting up HR measurement: $e');
      return false;
    }
  }

  void _onHrData(List<int> data) {
    final hr = _parseHeartRate(data);
    if (hr > 0) {
      _currentHeartRate = hr;
      _heartRateController.add(hr);
    }
  }

  /// Parse heart rate from BLE characteristic data
  /// Handles both 8-bit and 16-bit HR formats per Bluetooth SIG spec
  int _parseHeartRate(List<int> data) {
    if (data.isEmpty) return 0;

    final flags = data[0];
    final is16Bit = (flags & 0x01) != 0;

    if (is16Bit && data.length >= 3) {
      // 16-bit heart rate value (little-endian)
      return data[1] | (data[2] << 8);
    }

    // 8-bit heart rate value
    return data.length >= 2 ? data[1] : 0;
  }

  void _handleDisconnection() {
    _hrNotificationSubscription?.cancel();
    _hrNotificationSubscription = null;
    _hrMeasurementCharacteristic = null;
    _connectedDevice = null;
    _currentHeartRate = 0;
    _heartRateController.add(0);
    _updateState(HrConnectionState.disconnected);
  }

  void _updateState(HrConnectionState state) {
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
