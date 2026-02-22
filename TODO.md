# TODO

## UI Polish

- [x] **Typography**: Use Font Awesome caret-up/down for arrows, SF Rounded Bold for numbers
- [x] **Center box color**: Make it percentage transparent of background color instead of white/dark switch
- [x] **Ripple wave animation**: Background color change should ripple in direction of up/down

## UX Improvements

- [x] **Tap responsiveness**: Improve responsiveness for quick tap-tap-tap, haptic feedback keeping up

## Bug Fixes

- [x] **Long-tap scope**: Disconnect dialog triggers on long-tap anywhere - should only trigger on the connected indicator
- [ ] **Crash on long-tap**: Long-tapping the green connected indicator crashed the app (not reproducible now - monitor)

## UX Enhancements

- [x] **Finer resistance control**: Changed to 0-100% with 5% increments and decade-based color bands

## BLE Resilience

- [x] **FTMS indication parsing**: Subscribe to control point indications and detect command success/failure
- [x] **Machine status subscription**: Listen for control revocation and trainer reset events
- [x] **Degraded connection state**: Amber UI indicator when commands fail but BLE link is alive
- [x] **Graduated recovery**: Soft recovery at 3 failures, full reconnect at 6 failures
- [x] **Health check timer**: Periodic probe to detect stale connections
- [x] **Diagnostic log**: Circular buffer of timestamped BLE events for debugging
- [ ] **Expose diagnostic log in UI**: Add a debug screen to view BLE diagnostic log entries

## HealthKit Enhancements

- [ ] **Record speed (MPH)**: Read speed data from trainer via FTMS and save to HealthKit
- [ ] **Indoor cycling activity type**: Request `health` package add iOS indoor cycling support (currently shows as outdoor)

## Workout History

- [x] **Store workout history**: Persist completed workouts locally so users can review past sessions
  - [x] SQLite database with activities + activity_samples tables
  - [x] Auto-save on workout finish (activity + HR samples in one transaction)
  - [x] HISTORY button on home screen (idle state) and workout summary screen
  - [x] Activity list screen with arcade styling
  - [x] Activity detail screen with stat cards
  - [x] HR zone bar chart (5-zone model, pixel-art horizontal bars)
  - [x] PixelIcon.list icon type and ResistanceBandConfig.history background
- [x] **Seed data service**: In-app database seeding (long-press HISTORY title 10s) to populate 8 realistic test activities
- [x] **Configurable max HR**: Allow user to set max heart rate for zone calculations (v0.9.0 — UserSettingsService)
- [ ] **Delete activities**: Add swipe-to-delete or long-press delete on activity list

## UI Redesign

- [x] **Revise interface and redesign**: Complete retro pixel-art arcade UI overhaul
  - [x] **Gather reference designs**: Collected inspirational/reference UI designs
  - [x] **Theme foundation**: 8-color palette, Press Start 2P font, arcade widget system
  - [x] **Background system**: Dithered bands, pixel particles, speed streaks
  - [x] **HomeScreen conversion**: Resistance control, workout controls, stats bar
  - [x] **Secondary screens**: ScanScreen, HrScanSheet, WorkoutSummaryScreen
  - [x] **Animations**: 9 animation types + custom screen transitions + Reduce Motion support
  - [x] **App icons**: Pixel-art icons matching arcade aesthetic
  - [x] **8-bit polish pass**: Pixelated radar, sharp panel corners, wider resistance panel, button line fix, pixel celebration, HR sheet margins/spinner
  - [x] **Resistance panel v2**: Wide stair-stepped arrows, directional divider arcs, rounder panel corners (steps: 4), badge spacing, panel/button positioning
