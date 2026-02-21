import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/ble_service.dart';
import '../services/workout_service.dart';
import '../services/hr_service.dart';
import '../services/health_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/arcade_background.dart';
import '../widgets/arcade/arcade_panel.dart';
import '../widgets/arcade/arcade_button.dart';
import '../widgets/arcade/pixel_icon.dart';
import '../painters/radar_painter.dart';
import '../painters/resistance_band_config.dart';
import '../theme/page_transitions.dart';
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

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  List<ScanResult> _scanResults = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<TrainerConnectionState>? _connectionSubscription;
  bool _isScanning = false;
  bool _triedAutoConnect = false;
  bool _hasNavigated = false;
  bool _isAutoConnecting = true;
  String? _errorMessage;
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _connectionSubscription = widget.bleService.connectionState.listen(_onConnectionStateChanged);
    _tryAutoConnect();
  }

  @override
  void dispose() {
    _radarController.dispose();
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
    if (_hasNavigated) return;
    _hasNavigated = true;

    Navigator.of(context).pushReplacement(
      ArcadePageRoute(
        page: HomeScreen(
          bleService: widget.bleService,
          workoutService: widget.workoutService,
          hrService: widget.hrService,
          healthService: widget.healthService,
        ),
        transition: ArcadeTransition.slideRight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isAutoConnecting) {
      return Scaffold(
        body: ArcadeBackground(
          config: ResistanceBandConfig.scan,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Radar animation
                SizedBox(
                  width: 280,
                  height: 280,
                  child: AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: RadarPainter(
                          sweepAngle: _radarController.value,
                          ringPhase: (_radarController.value * 1.33) % 1.0,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'SEARCHING...',
                  style: AppTypography.label(fontSize: 10, color: AppColors.neonCyan),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: ArcadeBackground(
        config: ResistanceBandConfig.scan,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Title
              Text(
                'FIND TRAINER',
                style: AppTypography.button(fontSize: 14, color: AppColors.white),
              ),
              const SizedBox(height: 16),

              // Status area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildStatusArea(),
              ),

              const SizedBox(height: 16),

              // Device list
              Expanded(
                child: _buildDeviceList(),
              ),

              // Scan button
              Padding(
                padding: const EdgeInsets.all(24),
                child: _buildScanButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusArea() {
    if (_errorMessage != null) {
      return ArcadePanel.secondary(
        borderColor: AppColors.red,
        child: Row(
          children: [
            const PixelIcon.warning(size: 20, color: AppColors.red),
            const SizedBox(width: 12),
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

    if (widget.bleService.currentState == TrainerConnectionState.connecting) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.neonCyan,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'CONNECTING...',
            style: AppTypography.label(fontSize: 8, color: AppColors.neonCyan),
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
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.neonCyan,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'SEARCHING FOR TRAINERS...',
            style: AppTypography.label(fontSize: 8, color: AppColors.neonCyan),
          ),
        ],
      );
    }

    if (_scanResults.isEmpty) {
      return Text(
        'NO TRAINERS FOUND',
        style: AppTypography.label(fontSize: 8, color: AppColors.warmCream.withValues(alpha: 0.5)),
      );
    }

    return Text(
      '${_scanResults.length} TRAINER${_scanResults.length == 1 ? '' : 'S'} FOUND',
      style: AppTypography.label(fontSize: 8, color: AppColors.warmCream.withValues(alpha: 0.7)),
    );
  }

  Widget _buildDeviceList() {
    if (_scanResults.isEmpty && !_isScanning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PixelIcon.bluetooth(size: 64),
            const SizedBox(height: 16),
            Text(
              'MAKE SURE YOUR TRAINER\nIS ON AND IN RANGE',
              textAlign: TextAlign.center,
              style: AppTypography.secondary(fontSize: 7),
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

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: GestureDetector(
            onTap: widget.bleService.currentState == TrainerConnectionState.connecting
                ? null
                : () => _connectToDevice(device),
            child: ArcadePanel.secondary(
              borderColor: AppColors.magenta,
              child: Row(
                children: [
                  const PixelIcon.bluetooth(size: 24),
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
                  const PixelIcon.signalBars(size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanButton() {
    final isConnecting = widget.bleService.currentState == TrainerConnectionState.connecting;

    return ArcadeButton(
      label: isConnecting
          ? 'CONNECTING'
          : (_isScanning ? 'STOP SCAN' : 'SCAN AGAIN'),
      onTap: isConnecting
          ? null
          : (_isScanning ? _stopScan : _startScan),
      enabled: !isConnecting,
      scheme: ArcadeButtonScheme.gold,
    );
  }
}
