# Changelog

All notable changes to this project will be documented in this file.

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
