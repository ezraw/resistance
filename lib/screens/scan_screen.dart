import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../services/workout_service.dart';
import '../services/hr_service.dart';
import '../services/health_service.dart';
import 'home_screen.dart';

class ScanScreen extends StatefulWidget {
  final BleService bleService;
  final WorkoutService workoutService;
  final HrService hrService;
  final HealthService healthService;

  const ScanScreen({
    super.key,
    required this.bleService,
    required this.workoutService,
    required this.hrService,
    required this.healthService,
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<ScanResult> _scanResults = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<TrainerConnectionState>? _connectionSubscription;
  bool _isScanning = false;
  bool _triedAutoConnect = false;
  bool _hasNavigated = false;
  bool _isAutoConnecting = true;  // Start in auto-connect mode
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _connectionSubscription = widget.bleService.connectionState.listen(_onConnectionStateChanged);
    _tryAutoConnect();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _tryAutoConnect() async {
    if (_triedAutoConnect) return;
    _triedAutoConnect = true;

    final success = await widget.bleService.tryAutoConnect();
    if (success && mounted) {
      _navigateToHome();
    } else if (mounted) {
      setState(() {
        _isAutoConnecting = false;
      });
      _startScan();
    }
  }

  Future<void> _startScan() async {
    setState(() {
      _errorMessage = null;
      _scanResults = [];
    });

    final isAvailable = await widget.bleService.isBluetoothAvailable();
    if (!isAvailable) {
      setState(() {
        _errorMessage = 'Please enable Bluetooth';
      });
      return;
    }

    setState(() {
      _isScanning = true;
    });

    final resultsStream = await widget.bleService.startScan();
    _scanSubscription = resultsStream.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    });

    // Stop scanning after timeout
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isScanning) {
        _stopScan();
      }
    });
  }

  Future<void> _stopScan() async {
    await widget.bleService.stopScan();
    _scanSubscription?.cancel();
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await _stopScan();
    final success = await widget.bleService.connectToDevice(device);
    if (success && mounted) {
      _navigateToHome();
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Could not connect to trainer';
      });
    }
  }

  void _onConnectionStateChanged(TrainerConnectionState state) {
    if (state == TrainerConnectionState.connected && mounted) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    // Guard against multiple navigation calls
    if (_hasNavigated) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          bleService: widget.bleService,
          workoutService: widget.workoutService,
          hrService: widget.hrService,
          healthService: widget.healthService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen during initial auto-connect attempt
    if (_isAutoConnecting) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bluetooth_searching,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                'Looking for your trainer...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Trainer'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status area
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildStatusArea(),
            ),

            // Device list
            Expanded(
              child: _buildDeviceList(),
            ),

            // Scan button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildScanButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusArea() {
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.bleService.currentState == TrainerConnectionState.connecting) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 16),
          Text('Connecting...'),
        ],
      );
    }

    if (_isScanning) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 16),
          Text('Searching for trainers...'),
        ],
      );
    }

    if (_scanResults.isEmpty) {
      return const Text(
        'No trainers found',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Text(
      '${_scanResults.length} trainer${_scanResults.length == 1 ? '' : 's'} found',
      style: const TextStyle(color: Colors.grey),
    );
  }

  Widget _buildDeviceList() {
    if (_scanResults.isEmpty && !_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: 80,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Make sure your trainer is on\nand in range',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _scanResults.length,
      itemBuilder: (context, index) {
        final result = _scanResults[index];
        final device = result.device;
        final name = device.platformName.isNotEmpty
            ? device.platformName
            : 'Unknown Device';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.directions_bike),
            title: Text(name),
            subtitle: Text(device.remoteId.str),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.bleService.currentState == TrainerConnectionState.connecting
                ? null
                : () => _connectToDevice(device),
          ),
        );
      },
    );
  }

  Widget _buildScanButton() {
    final isConnecting = widget.bleService.currentState == TrainerConnectionState.connecting;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isConnecting
            ? null
            : (_isScanning ? _stopScan : _startScan),
        icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
        label: Text(_isScanning ? 'Stop Scan' : 'Scan Again'),
      ),
    );
  }
}
