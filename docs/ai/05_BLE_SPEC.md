# 05 — BLE Specification

Condensed from `BLE Implementation and Technical Risks`. This is an actionable rule set for the BLE layer.

## Permissions

### Android (`AndroidManifest.xml`)
```xml
<!-- Legacy (Android ≤ 11) -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<!-- Android 12+ -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<!-- Required for BLE scanning on all versions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### iOS (`Info.plist`)
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>HealthNest requires Bluetooth to receive safety data from the wristband.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>HealthNest requires Bluetooth to connect to the employee wristband sensor.</string>
```

## Rules

| # | Rule | Source |
|---|---|---|
| 1 | **Runtime permission gatekeeper** — never start a scan without checking `bluetoothScan`, `bluetoothConnect`, and `location` are all granted. Use `permission_handler`. | BLE doc §1.3 |
| 2 | **GPS-on trap** — on Android, verify the physical Location toggle is ON. If off, BLE scan returns zero results silently. | BLE doc §1.3 |
| 3 | **Scan by Service UUID only** — never filter by MAC address (iOS randomises it). Pass the band's Service UUID into `startScan(withServices:)`. | BLE doc §2.1, §2.2 |
| 4 | **BLE only** — no Bluetooth Classic. The ESP32 must broadcast BLE. | NFR-7.3 |
| 5 | **Notification characteristics** — subscribe to notifications. Do NOT poll with reads. | BLE doc §3, NFR-7.4 |
| 6 | **MTU request** — if payload > 23 bytes, request an increased MTU after connecting. | BLE doc §3 |
| 7 | **3 connection states** — `Connected` (show live data) / `Reconnecting` (show spinner + last known data) / `Disconnected` (show manual reconnect option). | FR-3.6, BLE doc §4.1 |
| 8 | **Auto-reconnect every 5 seconds** — on disconnect, retry automatically without user action. | NFR-2.1, BLE doc §4.2 |
| 9 | **Foreground service** — use `flutter_foreground_task` to prevent OS from killing the app in background. | BLE doc §4.3, FR-3.8 |
| 10 | **Byte parsing with bitwise ops** — BLE transmits raw byte arrays (`List<int>`). Combine bytes using `<<`, `>>`, `&`. Parser lives behind an interface. | BLE doc §5 |
| 11 | **BLE logic separated from UI** — connection engine in its own layer, UI listens to streams. | NFR-9.1 |

## Placeholder Constants

```dart
// DO NOT hardcode guessed values. These are placeholders until vendor confirms.
const String kServiceUuid        = 'TBD-SERVICE-UUID';
const String kSensorCharUuid     = 'TBD-SENSOR-CHAR-UUID';
// Add more characteristics as vendor specifies (HR, SpO2, accel, temp may be separate or combined).
```

## OPEN / UNRESOLVED

### 1. Service and Characteristic UUIDs — **TBD from vendor**
The embedded team has not provided the UUIDs yet. Use placeholder constants. T-10 is BLOCKED on this.

### 2. PACKET FORMAT — RESOLVED ✅ (Raw PPG)

Saud confirmed the app and backend pipeline design:
- **Wristband sends raw PPG samples at ~100 Hz** + accel at ~50 Hz (or similar high frequency raw bytes).
- This is required for proper HRV feature extraction (RMSSD) on the backend.
- The `PacketParser` interface targets parsing this raw byte stream into `SensorPacket`.
- BLE UUIDs are still pending from vendor. T-10 remains blocked on vendor UUIDs.
