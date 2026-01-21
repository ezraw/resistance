import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ble_service.dart';
import '../widgets/resistance_control.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  final BleService bleService;

  const HomeScreen({super.key, required this.bleService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentLevel;
  StreamSubscription<TrainerConnectionState>? _connectionSubscription;
  StreamSubscription<int>? _resistanceSubscription;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentLevel = widget.bleService.currentResistanceLevel;

    _connectionSubscription = widget.bleService.connectionState.listen(_onConnectionStateChanged);
    _resistanceSubscription = widget.bleService.resistanceLevel.listen(_onResistanceLevelChanged);

    // Hide status bar for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore status bar when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _connectionSubscription?.cancel();
    _resistanceSubscription?.cancel();
    super.dispose();
  }

  void _onConnectionStateChanged(TrainerConnectionState state) {
    if (state == TrainerConnectionState.disconnected && mounted) {
      // Go back to scan screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ScanScreen(bleService: widget.bleService),
        ),
      );
    }
  }

  void _onResistanceLevelChanged(int level) {
    if (mounted) {
      setState(() {
        _currentLevel = level;
      });
    }
  }

  Future<void> _increaseResistance() async {
    if (_isUpdating || _currentLevel >= 10) return;

    setState(() {
      _isUpdating = true;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Optimistic update
    setState(() {
      _currentLevel = (_currentLevel + 1).clamp(1, 10);
    });

    final success = await widget.bleService.increaseResistance();
    if (!success && mounted) {
      // Revert on failure
      setState(() {
        _currentLevel = widget.bleService.currentResistanceLevel;
      });
    }

    if (mounted) {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _decreaseResistance() async {
    if (_isUpdating || _currentLevel <= 1) return;

    setState(() {
      _isUpdating = true;
    });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Optimistic update
    setState(() {
      _currentLevel = (_currentLevel - 1).clamp(1, 10);
    });

    final success = await widget.bleService.decreaseResistance();
    if (!success && mounted) {
      // Revert on failure
      setState(() {
        _currentLevel = widget.bleService.currentResistanceLevel;
      });
    }

    if (mounted) {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _disconnect() async {
    await widget.bleService.disconnect();
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect'),
        content: const Text('Disconnect from trainer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _disconnect();
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onLongPress: _showDisconnectDialog,
        child: Stack(
          children: [
            // Main resistance control (full screen)
            ResistanceControl(
              currentLevel: _currentLevel,
              onIncrease: _increaseResistance,
              onDecrease: _decreaseResistance,
              isUpdating: _isUpdating,
            ),

            // Connection status indicator (top-left, subtle)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: _buildConnectionIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.bleService.isConnected ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            widget.bleService.isConnected ? 'Connected' : 'Disconnected',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
