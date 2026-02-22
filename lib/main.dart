import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'screens/scan_screen.dart';
import 'services/ble_service.dart';
import 'services/workout_service.dart';
import 'services/hr_service.dart';
import 'services/health_service.dart';
import 'services/activity_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (optional - app works without it)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Pass all uncaught Flutter errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught async errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    // Firebase not configured yet - app will work without crash reporting
    debugPrint('Firebase not initialized: $e');
  }

  // Initialize activity history database
  final activityService = ActivityService.create();
  await activityService.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(ResistanceApp(activityService: activityService));
}

class ResistanceApp extends StatefulWidget {
  final ActivityService activityService;

  const ResistanceApp({super.key, required this.activityService});

  @override
  State<ResistanceApp> createState() => _ResistanceAppState();
}

class _ResistanceAppState extends State<ResistanceApp> {
  final BleService _bleService = BleService();
  final WorkoutService _workoutService = WorkoutService();
  final HrService _hrService = HrService();
  final HealthService _healthService = HealthService();

  @override
  void dispose() {
    _bleService.dispose();
    _workoutService.dispose();
    _hrService.dispose();
    widget.activityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resistance Control',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.data,
      home: ScanScreen(
        bleService: _bleService,
        workoutService: _workoutService,
        hrService: _hrService,
        healthService: _healthService,
        activityService: widget.activityService,
      ),
    );
  }
}
