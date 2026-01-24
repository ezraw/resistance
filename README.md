# Resistance Control App

A simple Flutter app to control the resistance level of a Wahoo Kickr Core 2 smart trainer via Bluetooth, independent of Zwift.

## Problem

When using a Zwift Ride with Kickr Core 2, there's no way to adjust trainer resistance without running Zwift. This makes standalone workouts (like following a YouTube spin class) impossible without manual resistance control.

## Solution

A minimal mobile app with two buttons (up/down) and a level display (1-10) that connects directly to the Kickr Core 2 via Bluetooth FTMS protocol.

## Features (MVP)

- Connect to Kickr Core 2 via Bluetooth
- Display current resistance level (1-10)
- Increase/decrease resistance with large tap targets
- Auto-reconnect to previously paired trainer
- Simple, distraction-free UI for workout use

## Future Enhancements

- Zwift Ride handlebar control integration (use shift buttons to adjust resistance)
- Live power/cadence/speed display
- Preset resistance profiles
- Android support

## Technical Details

- **Framework**: Flutter (cross-platform, iOS first)
- **Bluetooth**: flutter_blue_plus library
- **Protocol**: FTMS (Fitness Machine Service) - Bluetooth SIG standard
- **Trainer Communication**:
  - Service UUID: `0x1826`
  - Control Point: `0x2AD9`
  - Set Resistance: Op Code `0x04`

## Requirements

- iOS 13.0+ (Bluetooth LE required)
- Wahoo Kickr Core 2 (or any FTMS-compatible trainer)
- Apple Developer account (for device installation)

## Development Setup

1. Install Flutter: `brew install --cask flutter`
2. Install Xcode from developer.apple.com
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to launch on connected device

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/
│   ├── home_screen.dart      # Main resistance control UI
│   └── scan_screen.dart      # Device scanning/connection
├── services/
│   └── ble_service.dart      # Bluetooth FTMS communication
└── widgets/
    └── resistance_control.dart  # Up/Down/Level widget
```

## License

MIT
