# Changelog

All notable changes to this project will be documented in this file.

## [0.4.0] - 2026-01-25

### Changed
- **Resistance range**: Changed from 1-10 levels to 0-100% with 5% increments
- **Auto-start at 0%**: Trainer automatically sets to 0% resistance on connection
- **Color scheme**: New decade-based color bands (11 colors: 0-9%, 10-19%, ... 90-99%, 100%)
- **Animation style**: Replaced directional wave animation with smooth cross-fade (only triggers at decade boundaries)
- **Startup screen**: New "Looking for your trainer..." loading screen during auto-connect attempt

### Added
- **Screen wakelock**: Screen stays awake during use to prevent interruption during workouts

### Fixed
- **Double navigation**: Fixed screen sliding multiple times when connecting to trainer (duplicate navigation calls)
- **Resistance display bounce**: Fixed display briefly showing intermediate values during rapid button tapping

### Dependencies
- Added `wakelock_plus: ^1.2.8` for screen wake management

## [0.3.1] - 2026-01-24

### Security
- **Secure device ID storage**: BLE device IDs now stored in iOS Keychain via `flutter_secure_storage` instead of plaintext SharedPreferences
- **Debug logging**: Replaced `print()` with `debugPrint()` throughout BLE services - logs no longer appear in release builds

### Dependencies
- Added `flutter_secure_storage: ^9.2.2` for secure credential storage

## [0.3.0] - 2026-01-24

### Added
- **Apple Health Integration**: Workouts automatically save to Apple Health
  - Duration and activity type (Cycling) saved
  - Individual heart rate samples saved with timestamps
  - Apple Fitness calculates heart rate zones automatically
  - Status indicator on workout summary screen
  - Permission request on first save attempt

- **Firebase Crashlytics**: Automatic crash reporting
  - Captures uncaught Flutter errors
  - Captures async errors
  - Crash reports uploaded on next app launch

### Technical Details
- `HealthService`: Apple HealthKit wrapper using `health` package
- `HeartRateReading`: New class to track HR with timestamps for HealthKit
- `WorkoutService.workoutStartTime`: Track absolute start time for HealthKit
- `WorkoutService.heartRateReadings`: Exposes HR list for HealthKit integration
- 76 unit and widget tests (up from 71)

### Dependencies
- Added `firebase_core: ^3.8.1`
- Added `firebase_crashlytics: ^4.2.1`
- Added `health: ^11.1.0`

### Setup Required
- Firebase project configuration (`flutterfire configure`)
- HealthKit capability must be added in Xcode

## [0.2.1] - 2026-01-24

### Fixed
- **Black screen after HR connection**: Fixed critical bug where connecting to HR monitor would cause black screen. Root cause was duplicate `Navigator.pop()` calls in HR scan sheet.
- **Bluetooth scan reliability**: Added Bluetooth adapter readiness checks before scanning for trainers or HR monitors. Scans now wait up to 5 seconds for Bluetooth to be ready.
- **Scan error handling**: BLE scan failures are now caught and handled gracefully instead of crashing.

### Added
- **HR connection before workout**: Heart rate monitor can now be connected from idle screen (top-right button) before starting a workout, not just during active workout.
- **Confetti celebration**: Celebratory confetti animation plays when workout summary screen appears.

### Changed
- HR scan sheet now only dismisses on successful connection from `_connectToDevice`, not from connection state listener.
- **Simplified workout controls**: Removed Finish button from active workout state. Users must now pause before finishing, which prevents accidental workout termination.
- Workout control buttons now use Wrap layout for better responsiveness on different screen sizes.
- Xcode scheme defaults to Release build configuration.

### Dependencies
- Added `confetti: ^0.7.0` for workout completion animation

## [0.2.0] - 2026-01-24

### Added
- **Workout Timer**: Track your workout duration
  - Start/pause/resume/restart/finish controls
  - Elapsed time display (MM:SS or HH:MM:SS)
  - Stats bar at top during active workout
  - Workout summary screen after finishing

- **Heart Rate Monitor Support**: Connect BLE heart rate monitors
  - Scan and connect to HR monitors (Polar, Wahoo, etc.)
  - Real-time heart rate display during workout
  - Supports both 8-bit and 16-bit HR formats per BLE spec
  - Average and max HR tracking in workout summary
  - Tap HR display to connect/reconnect

- **Workout Controls**: Bottom button bar
  - Start button when idle
  - Pause button during active workout
  - Resume/Restart/Finish when paused
  - Haptic feedback on button presses

- **UI Improvements**
  - Semi-transparent stats bar overlay
  - Connection indicator only shows when not in workout
  - Directional wave animations for resistance changes
  - Adjusted control panel padding for overlay elements

### Technical Details
- `WorkoutService`: State machine with timer (idle → active ↔ paused → finished)
- `HrService`: BLE Heart Rate Service (0x180D) with measurement parsing (0x2A37)
- `WorkoutStatsBar`, `WorkoutControls`, `HeartRateDisplay` widgets
- `HrScanSheet` bottom sheet for HR monitor discovery
- `WorkoutSummaryScreen` for post-workout stats
- 71 unit and widget tests

## [0.1.0] - 2026-01-20

### Added
- Initial MVP implementation
- **BLE Service**: Connect to FTMS-compatible trainers (Wahoo Kickr Core 2)
  - Scan for nearby trainers
  - Auto-reconnect to last connected device
  - Set resistance level via FTMS Control Point (0x2AD9)
- **Scan Screen**: Device discovery UI
  - Shows list of available trainers
  - Connection status indicators
  - Auto-scan on app launch
- **Home Screen**: Resistance control UI
  - Full-screen immersive experience
  - Color gradient background (green → yellow → orange → red)
  - Rounded control panel with up/down arrows
  - Large level number display (1-10)
  - Haptic feedback on button press
  - Pulse animation for tap feedback
  - Smooth color transitions between levels
  - Long-press to disconnect
- **iOS Configuration**
  - Bluetooth permissions configured
  - Background Bluetooth mode enabled
  - Minimum iOS 13.0 for BLE support
- **Documentation**
  - README with project overview
  - Design document with technical specifications
  - Widget tests for resistance control

### Technical Details
- Flutter 3.38.7
- flutter_blue_plus for BLE communication
- shared_preferences for device persistence
- FTMS protocol implementation (Service 0x1826, Control Point 0x2AD9)
