import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/hr_service.dart';

/// Bottom sheet for discovering and connecting to HR monitors
class HrScanSheet extends StatefulWidget {
  final HrService hrService;

  const HrScanSheet({super.key, required this.hrService});

  /// Show the HR scan sheet as a modal bottom sheet
  static Future<void> show(BuildContext context, HrService hrService) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => HrScanSheet(hrService: hrService),
    );
  }

  @override
  State<HrScanSheet> createState() => _HrScanSheetState();
}

class _HrScanSheetState extends State<HrScanSheet> {
  List<ScanResult> _scanResults = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<HrConnectionState>? _connectionSubscription;
  bool _isScanning = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _connectionSubscription = widget.hrService.connectionState.listen(_onConnectionStateChanged);
    _startScan();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    widget.hrService.stopScan();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _errorMessage = null;
      _scanResults = [];
      _isScanning = true;
    });

    final resultsStream = await widget.hrService.startScan();
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
    await widget.hrService.stopScan();
    _scanSubscription?.cancel();
    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await _stopScan();
    final success = await widget.hrService.connectToDevice(device);
    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Could not connect to device';
      });
    }
  }

  void _onConnectionStateChanged(HrConnectionState state) {
    if (state == HrConnectionState.connected && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Connect Heart Rate Monitor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Status area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStatusArea(),
              ),

              const SizedBox(height: 8),

              // Device list
              Expanded(
                child: _buildDeviceList(scrollController),
              ),

              // Scan button
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildScanButton(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusArea() {
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.hrService.currentState == HrConnectionState.connecting) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Text(
            'Connecting...',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      );
    }

    if (_isScanning) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Text(
            'Searching for HR monitors...',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      );
    }

    if (_scanResults.isEmpty) {
      return Text(
        'No HR monitors found',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      );
    }

    return Text(
      '${_scanResults.length} device${_scanResults.length == 1 ? '' : 's'} found',
      style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
    );
  }

  Widget _buildDeviceList(ScrollController scrollController) {
    if (_scanResults.isEmpty && !_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_searching,
              size: 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Make sure your HR monitor\nis on and in range',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _scanResults.length,
      itemBuilder: (context, index) {
        final result = _scanResults[index];
        final device = result.device;
        final name = device.platformName.isNotEmpty
            ? device.platformName
            : 'Unknown HR Monitor';

        return Card(
          color: Colors.white.withValues(alpha: 0.1),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: Text(
              name,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              device.remoteId.str,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            onTap: widget.hrService.currentState == HrConnectionState.connecting
                ? null
                : () => _connectToDevice(device),
          ),
        );
      },
    );
  }

  Widget _buildScanButton() {
    final isConnecting = widget.hrService.currentState == HrConnectionState.connecting;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isConnecting
            ? null
            : (_isScanning ? _stopScan : _startScan),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withValues(alpha: 0.2),
          foregroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        icon: Icon(_isScanning ? Icons.stop : Icons.refresh),
        label: Text(_isScanning ? 'Stop Scan' : 'Scan Again'),
      ),
    );
  }
}
