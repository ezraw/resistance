# Changelog

All notable changes to this project will be documented in this file.

## [0.6.4] - 2026-02-22

### Fixed
- **HR scan sheet styling**: Replaced plain `Container` with `ArcadePanel` for pixel stair-step corners consistent with the arcade style guide. Removed smooth-corner drag handle bar. Added bottom margin so the sheet floats above the screen edge.
- **Resistance display bouncing on rapid taps**: Fixed race condition where overlapping debounced BLE writes could cause the resistance number to bounce between intermediate values. `_hasPendingUpdate` now only clears when the completed write matches the latest pending level.

### Added
- Debounce logic unit tests (6 tests covering overlapping writes, BLE stream suppression, rapid increase/decrease, slow taps, and failure scenarios)

### Technical Details
- 206 unit and widget tests (up from 200)
- `flutter analyze` reports zero issues

## [0.6.3] - 2026-02-21

### Fixed
- **DONE button broken rendering**: Gold fill area only sized to text content, leaving darker base color visible as a separate rectangle behind it. Fixed by adding `IntrinsicWidth` + `CrossAxisAlignment.stretch` to `ArcadeButton` so the top color fill stretches to full button width
- **PAUSE button too small**: Increased `minWidth` from 120 to 200 so it matches the visual weight of RESUME/RESTART/FINISH buttons

### Added
- **DONE button checkmark icon**: Added `PixelIcon.check` so DONE button is consistent with all other buttons having icons
- `PixelIconType.check`: Pixel-art checkmark icon (2x2 blocks on 16x16 grid)

## [0.6.2] - 2026-02-21

### Changed
- **Pixel stair-step corners**: All arcade containers (panels, buttons, badges) now use 2-step notched staircase corners via `PixelContainer` instead of smooth `BorderRadius.circular()`. Matches classic 8-bit arcade "CREDIT" button aesthetic.
- **Disabled increment buttons**: Bumped fill/border alpha from 0.2 to 0.35 and text alpha from 0.3 to 0.45 for better visibility when +5 at 100% or -5 at 0%
- **Workout summary layout**: DONE button is now pinned at the bottom of the safe area instead of being pushed off-screen by layout

### Added
- `PixelBorderPainter`: CustomPainter that draws fill + stroke with stepped pixel corners using `StrokeJoin.miter` for sharp 90-degree joins
- `buildPixelBorderPath()`: Standalone path function reusable for both painting and clipping
- `PixelContainer`: Drop-in replacement for `Container` + `BoxDecoration` + `BorderRadius` in arcade widgets
- Pixel border painter tests (path bounds, closed path, inset behavior, shouldRepaint)
- Pixel container widget tests (renders child, applies padding, CustomPaint + ClipPath presence)

### Technical Details
- `ArcadePanel.borderRadius` replaced with `notchSize` parameter
- Style guide updated with pixel corner notch size table and `BorderRadius.circular()` pitfall

## [0.6.1] - 2026-02-21

### Changed
- **Radar animation**: Rewritten with pixel block rendering (4x4 stepped rectangles) instead of smooth lines
- **Radar size**: Increased from 160x160 to 280x280 on scan screen for better visibility
- **Arcade panel corners**: Reduced border radius from 16 to 4 (primary) and 12 to 3 (secondary) for sharper 8-bit look
- **Arcade panel border**: Increased primary border width from 3 to 6 for visibly pixelated corners
- **Arcade button**: Reduced corner radius from 10/8px to 2/0px for sharp pixelated look, thickened border to 3px, wrapped in UnconstrainedBox to prevent stretching
- **Resistance control**: Replaced arrow icons with solid gold +5/-5 buttons, narrowed panel (maxWidth 240)
- **Workout complete screen**: Removed play icon, title now 32pt centered with FittedBox, added random encouraging affirmations
- **Health save indicator**: Removed bullet icon from "Saved to Apple Health" text (now centered text only)
- **HR scan sheet**: Added horizontal margins (no longer edge-to-edge), sharp 4px corners, pixel close button, animated dot sequence spinner
- **Confetti replaced**: Replaced smooth confetti with pixel celebration painter (falling colored squares in arcade palette)

### Added
- `PixelCelebrationPainter`: CustomPainter rendering 45 gravity-affected pixel squares bursting from top center
- `PixelIconType.close`: Pixel X icon for close buttons
- 10 encouraging workout affirmations shown randomly on completion screen
- Pixel celebration painter tests

### Removed
- `confetti` package dependency (replaced by native pixel celebration)

### Technical Details
- 186 unit and widget tests (up from 179)
- `flutter analyze` reports zero issues

## [0.6.0] - 2026-02-21

### Added
- **Retro pixel-art arcade UI redesign**: Complete visual overhaul with kidcore/Y2K aesthetic
  - 8-color palette: hotPink, magenta, purpleMagenta, electricViolet, deepViolet, nightPlum, neonCyan, warmCream
  - Press Start 2P pixel font (bundled as asset for offline use)
  - Custom pixel-art icons via CustomPainter (13 types: arrows, heart, play, pause, stop, restart, stopwatch, warning, bluetooth, signalBars, greenDot, close)
  - Dithered background band system with Bayer 4x4 ordered dithering
  - Floating pixel particles and diagonal speed streaks (RepaintBoundary isolated)
  - Resistance-reactive backgrounds (color bands shift with 0-100% level)
- **Arcade widget system**: Reusable ArcadePanel, ArcadeButton, ArcadeBadge components
  - ArcadeButton: 3D depth effect, press/release animation (50ms down, 150ms elasticOut spring back), 4 color schemes (gold, magenta, orange, red)
  - ArcadePanel: nightPlum fill with colored border, primary and secondary variants
  - ArcadeBadge: compact HUD badges with icon + text
- **9 animation types**: Button press/release, arrow tap pulse, START button throb, radar sweep, particle drift, streak shimmer, background breathing, resistance reaction pulse, HR-synced pulse
- **Custom screen transitions**: ArcadePageRoute with slideRight, slideUp, and fadeScale transitions
- **Radar sweep animation**: Scan screen shows phosphor-trail radar during auto-connect
- **Accessibility**: All animations respect iOS Reduce Motion setting (MediaQuery.disableAnimations)
- **Pixel-art app icons**: Programmatically generated matching the arcade aesthetic (gold up-arrow on nightPlum with magenta border, cyan corner accents)

### Changed
- All screens converted to arcade aesthetic: HomeScreen, ScanScreen, HrScanSheet, WorkoutSummaryScreen
- Resistance control uses ArcadePanel with magenta border and pixel-art arrow icons
- Workout controls use ArcadeButton with scheme-specific colors
- Workout stats bar uses ArcadeBadge widgets for timer, warning, and HR
- Connection and HR indicators use ArcadeBadge
- Confetti colors updated to match 8-color palette
- All button/heading text is now uppercase per arcade convention

### Removed
- `font_awesome_flutter` dependency (replaced by custom pixel-art icons)
- Old Material Design dark theme styling
- RadialGradient background from resistance control

### Dependencies
- Added `google_fonts: ^6.2.1`
- Removed `font_awesome_flutter: ^10.6.0`

### Technical Details
- 179 unit and widget tests (up from 115)
- `flutter analyze` reports zero issues
- Background system uses cached rendering with RepaintBoundary for particle performance
- Bayer 4x4 dithering for smooth band color transitions
- All CustomPainters guard against zero-size rendering

## [0.5.0] - 2026-02-21

### Added
- **FTMS indication parsing**: Control point indications are now subscribed and parsed, detecting success/failure of every resistance command
- **FTMS machine status subscription**: Listens on Machine Status characteristic (0x2ADA) for control revocation and trainer reset events
- **Degraded connection state**: New `TrainerConnectionState.degraded` shown as amber dot + "Reconnecting..." when commands are failing but BLE link is alive
- **Graduated recovery**: After 3 consecutive failures, soft recovery (re-request control + resend resistance); after 6 failures, full disconnect/reconnect cycle
- **Health check timer**: 30-second periodic check detects stale connections where no command has succeeded in 60+ seconds
- **BLE diagnostic log**: Circular buffer (100 entries) of timestamped BLE events for debugging connection issues
- **Workout degraded warning**: Amber warning icon appears in workout stats bar when connection is degraded
- **Failure snackbar**: User-visible feedback when resistance commands fail (instead of silent revert)

### Changed
- `isConnected` now returns `true` for both `connected` and `degraded` states, so resistance controls remain usable during recovery
- `dispose()` now properly cleans up without adding events to closed stream controllers

### Technical Details
- `FtmsResultCodes`: FTMS Control Point result code constants (success, controlNotPermitted, etc.)
- `FtmsMachineStatus`: Machine Status event constants (reset, controlPermissionLost)
- `BleDiagnosticLog`: Lightweight circular buffer log with `debugPrint` output
- 115 unit tests (up from 76)

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
