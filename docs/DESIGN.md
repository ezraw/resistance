# App Design Document

## Overview

Resistance Control App is a minimal Flutter application for controlling Wahoo Kickr Core 2 trainer resistance via Bluetooth Low Energy (BLE) using the FTMS protocol.

## User Experience

### Connection Flow

1. User opens app
2. App scans for FTMS-compatible Bluetooth devices
3. Available trainers appear in a list
4. User taps trainer to connect
5. App navigates to main control screen

### Subsequent Uses

- App remembers last connected device
- Auto-connects on launch if device is available
- Falls back to scan screen if device not found

### Main Control Screen

```
┌────────────────────────────────────┐
│         Connected ●                │
│                                    │
│              ▲                     │
│             UP                     │
│                                    │
│              5                     │
│                                    │
│            DOWN                    │
│              ▼                     │
│                                    │
└────────────────────────────────────┘
```

- Large tap targets for up/down (entire top/bottom half of screen)
- Current level prominently displayed in center
- Connection status indicator at top
- Tap anywhere in top half = increase resistance
- Tap anywhere in bottom half = decrease resistance

## Technical Architecture

### Bluetooth Communication

#### FTMS Protocol

The Fitness Machine Service (FTMS) is a Bluetooth SIG standard for fitness equipment control.

**Service UUID**: `0x1826`

**Key Characteristics**:

| UUID | Name | Purpose |
|------|------|---------|
| `0x2ACC` | Fitness Machine Feature | Read supported features |
| `0x2AD6` | Supported Resistance Level Range | Read min/max resistance |
| `0x2AD9` | Fitness Machine Control Point | Write commands |
| `0x2ADA` | Fitness Machine Status | Notifications |

**Control Point Commands**:

| Op Code | Command | Data |
|---------|---------|------|
| `0x00` | Request Control | None |
| `0x01` | Reset | None |
| `0x04` | Set Target Resistance Level | UINT8 (0.1 resolution) |

**Control Flow**:

1. Connect to device
2. Discover FTMS service (`0x1826`)
3. Write `0x00` to Control Point to request control
4. Wait for indication (response code `0x01` = success)
5. Write `[0x04, resistance_value]` to set resistance

### Resistance Mapping

| App Level | FTMS Value | Percentage |
|-----------|------------|------------|
| 1 | 10 | 10% |
| 2 | 20 | 20% |
| 3 | 30 | 30% |
| 4 | 40 | 40% |
| 5 | 50 | 50% |
| 6 | 60 | 60% |
| 7 | 70 | 70% |
| 8 | 80 | 80% |
| 9 | 90 | 90% |
| 10 | 100 | 100% |

Note: FTMS resistance is UINT8 with 0.1 resolution, so level 5 = 50 (representing 50%).

### State Management

Simple `StatefulWidget` approach for MVP:

```
AppState {
  connectionState: disconnected | connecting | connected
  currentLevel: 1-10
  deviceId: String? (for auto-reconnect)
}
```

### Error Handling

- Connection timeout: Show "Couldn't connect" with retry button
- Connection lost: Show "Reconnecting..." and auto-retry 3 times
- Bluetooth off: Show "Please enable Bluetooth" message
- No devices found: Show "No trainers found" with rescan button

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_blue_plus: ^1.35.0  # BLE communication
  shared_preferences: ^2.3.0  # Persist last device ID
```

## iOS Configuration

### Info.plist Keys

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect to your bike trainer and control resistance.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to connect to your bike trainer and control resistance.</string>
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
</array>
```

### Minimum iOS Version

iOS 13.0 (required for modern BLE APIs)

## Future Considerations

### Zwift Ride Handlebar Controls

The Zwift Ride controllers can be integrated as a second Bluetooth connection:

- Service UUID: `FC82`
- Device name: "Zwift SF2"
- Handshake: Write "RideOn" to receive button events
- Button data: Protocol buffer message ID `0x23`

Shift buttons could map to resistance up/down when not using Zwift.

### Additional Features

- Power/cadence/speed display (data available via FTMS Indoor Bike Data characteristic `0x2AD2`)
- Workout profiles (save/load resistance sequences)
- Interval timer integration
