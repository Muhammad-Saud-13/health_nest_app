# 02 — Architecture

## State Management

**Provider** — chosen for simplicity and sufficient capability for this app's needs. See `06_DECISIONS.md` D-01.

## Folder Structure

```
lib/
├── core/
│   ├── config.dart          # USE_MOCKS flag, app constants
│   ├── theme.dart            # Colours, text styles, spacing
│   ├── constants.dart        # BLE UUIDs (placeholder), thresholds
│   ├── utils/                # Formatters, helpers
│   └── errors/               # App exception classes
├── data/
│   ├── models/               # User, ShiftSession, Classification,
│   │                         #   Spo2Reading, Alert, CheckIn, SensorPacket
│   ├── sources/
│   │   ├── wearable_source.dart          # Interface
│   │   ├── mock_wearable_source.dart     # Fake stream with scripted scenarios
│   │   └── ble_wearable_source.dart      # Real BLE (T-10, blocked)
│   └── repositories/
│       ├── auth_repository.dart          # Interface
│       ├── data_repository.dart          # Interface (classifications, history, alerts, check-ins)
│       ├── mock_auth_repository.dart
│       ├── mock_data_repository.dart
│       ├── api_auth_repository.dart      # Real API (T-11, blocked)
│       ├── api_data_repository.dart      # Real API (T-11, blocked)
│       ├── local_store.dart              # Offline queue interface + impl
│       └── packet_parser.dart            # Interface + impl (swappable format)
├── features/
│   ├── auth/          # presentation/ + state/
│   ├── home/          # presentation/ + state/
│   ├── connection/    # presentation/ + state/
│   ├── alerts/        # presentation/ + state/

│   ├── checkin/       # presentation/ + state/
│   ├── history/       # presentation/ + state/
│   └── settings/      # presentation/
└── main.dart
```

## Interfaces & Implementations

| Interface | Mock (now) | Real (later) | Notes |
|---|---|---|---|
| `WearableSource` | `MockWearableSource` — emits fake HR, SpO2, accel, temp stream with scripted stress spikes, disconnects, low SpO2 events | `BleWearableSource` — flutter_blue_plus | Switched via `USE_MOCKS` |
| `AuthRepository` | `MockAuthRepository` — hardcoded users, fake login/logout | `ApiAuthRepository` — HTTP calls | Switched via `USE_MOCKS` |
| `DataRepository` | `MockDataRepository` — returns canned classifications, history, alerts | `ApiDataRepository` — HTTP calls | Switched via `USE_MOCKS` |
| `LocalStore` | sqflite-based offline queue (see D-09) — ordered inserts/deletes, ~17 MB per 8h shift | Same impl, production-ready | Always real; queue for offline |
| `PacketParser` | Interface — parse raw byte stream into `SensorPacket` model | Design targets raw PPG at ~100 Hz + accel at ~50 Hz (D-19). Vendor UUIDs still TBD. | See `05_BLE_SPEC.md` |

## Packet Parser

The parser **must** live in its own class behind an interface. The app designs for **raw PPG at ~100 Hz and accel at ~50 Hz** (D-19), but vendor UUIDs and byte layout are still TBD (see `05_BLE_SPEC.md`). The mock source bypasses the parser and emits `SensorPacket` objects directly; the real BLE source must go through the parser.

## Data Models (mirrored from DB, app-relevant fields only)

`User`, `ShiftSession`, `Classification`, `Spo2Reading`, `Alert`, `CheckIn`, `SensorPacket` (local-only, not in DB).

## Planned Packages

| Package | Purpose |
|---|---|
| `provider` | State management |
| `flutter_blue_plus` | BLE communication (T-10) |
| `permission_handler` | Runtime permissions |
| `flutter_foreground_task` | Keep BLE alive in background |
| `sqflite` | Local offline queue storage — ordered inserts/deletes, ~17 MB/shift (D-09) |
| `flutter_secure_storage` | Secure JWT token storage (D-21) |
| `http` | REST API calls (T-11) |

## Layer Diagram

```
┌─────────────────────────────────────────┐
│              UI / Features              │  Widgets, screens
├─────────────────────────────────────────┤
│           State (Providers)             │  ChangeNotifiers
├──────────────┬──────────────────────────┤
│  Repositories│   WearableSource         │  Interfaces
│  (Auth, Data)│   (Mock / BLE)           │
├──────────────┤──────────────────────────┤
│  LocalStore  │   PacketParser           │  Offline queue / byte parsing
├──────────────┴──────────────────────────┤
│        core/ (config, theme, utils)     │
└─────────────────────────────────────────┘
          │                    │
     REST API              BLE radio
     (backend)             (wristband)
```

Data flows **down** from UI → Provider → Repository/Source, and **up** via streams and `notifyListeners()`.

## Data Flow & HR Processing Strategy (D-23)

1. **SpO2**: Direct from BLE stream → UI display.
2. **Live Local HR**: App runs a lightweight local PPG peak detector on incoming byte stream for instant UI feedback.
3. **Backend Processing**: App streams 5s raw PPG batches (`POST /sensor-data`) to backend. Backend computes precise HR + HRV (RMSSD) + ML State (Calm/Stressed) and returns classification state & alerts to the app.
