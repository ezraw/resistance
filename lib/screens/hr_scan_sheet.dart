import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/hr_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/arcade/arcade_panel.dart';
import '../widgets/arcade/arcade_button.dart';
import '../widgets/arcade/pixel_icon.dart';

/// Bottom sheet for discovering and connecting to HR monitors.
class HrScanSheet extends StatefulWidget {
  final HrService hrService;

  const HrScanSheet({super.key, required this.hrService});

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
  int _dotCount = 1;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();
    _connectionSubscription = widget.hrService.connectionState.listen(_onConnectionStateChanged);
    _startScan();
    // Animate dot sequence for scanning indicator
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount % 3) + 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
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
    if (mounted) {
      setState(() {});
    }
  }

  String get _scanningDots => '.' * _dotCount;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.nightPlum,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              border: Border.all(
                color: AppColors.magenta,
                width: 3,
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.warmCream.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const PixelIcon.heart(size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'CONNECT HR MONITOR',
                          style: AppTypography.button(fontSize: 10, color: AppColors.white),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const PixelIcon.close(
                          size: 24,
                          color: AppColors.warmCream,
                        ),
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
          ),
        );
      },
    );
  }

  Widget _buildStatusArea() {
    if (_errorMessage != null) {
      return ArcadePanel.secondary(
        borderColor: AppColors.red,
        child: Row(
          children: [
            const PixelIcon.warning(size: 16, color: AppColors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: AppTypography.label(fontSize: 8, color: AppColors.red),
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
          Text(
            'CONNECTING$_scanningDots',
            style: AppTypography.label(fontSize: 8, color: AppColors.warmCream.withValues(alpha: 0.7)),
          ),
        ],
      );
    }

    if (_isScanning) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'SEARCHING$_scanningDots',
            style: AppTypography.label(fontSize: 8, color: AppColors.warmCream.withValues(alpha: 0.7)),
          ),
        ],
      );
    }

    if (_scanResults.isEmpty) {
      return Text(
        'NO HR MONITORS FOUND',
        style: AppTypography.label(fontSize: 8, color: AppColors.warmCream.withValues(alpha: 0.5)),
      );
    }

    return Text(
      '${_scanResults.length} DEVICE${_scanResults.length == 1 ? '' : 'S'} FOUND',
      style: AppTypography.label(fontSize: 8, color: AppColors.warmCream.withValues(alpha: 0.7)),
    );
  }

  Widget _buildDeviceList(ScrollController scrollController) {
    if (_scanResults.isEmpty && !_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PixelIcon.heart(
              size: 48,
              color: AppColors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'MAKE SURE YOUR HR MONITOR\nIS ON AND IN RANGE',
              textAlign: TextAlign.center,
              style: AppTypography.secondary(fontSize: 7),
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

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: GestureDetector(
            onTap: widget.hrService.currentState == HrConnectionState.connecting
                ? null
                : () => _connectToDevice(device),
            child: ArcadePanel.secondary(
              borderColor: AppColors.magenta,
              child: Row(
                children: [
                  const PixelIcon.heart(size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: AppTypography.label(fontSize: 8),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          device.remoteId.str,
                          style: AppTypography.secondary(fontSize: 6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanButton() {
    final isConnecting = widget.hrService.currentState == HrConnectionState.connecting;

    return ArcadeButton(
      label: isConnecting
          ? 'CONNECTING'
          : (_isScanning ? 'STOP SCAN' : 'SCAN AGAIN'),
      onTap: isConnecting
          ? null
          : (_isScanning ? _stopScan : _startScan),
      enabled: !isConnecting,
      scheme: ArcadeButtonScheme.red,
    );
  }
}
