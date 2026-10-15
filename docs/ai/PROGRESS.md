# PROGRESS — Task Tracker

## Done

- [x] **T-01: Project Skeleton** (Completed 2026-10-08)
- [x] **T-02: Mock Layer** (Completed 2026-10-09)
- [x] **T-03: Auth Screens** (Completed 2026-10-11)
- [x] **T-04: Home Screen** (Completed 2026-10-11)
- [x] **T-05: Connection UI** (Completed 2026-10-12)
- [x] **T-06: Sustained Stress Notification Display** (Completed 2026-10-15)

## In Progress
    
_(none currently - ready for T-07)_

## Next (ordered)

---

### T-01: Project Skeleton
**Covers:** NFR-9.3, NFR-7.1, setup for all features
**Depends on:** —
**Done when:**
- `flutter create` run (or existing project cleaned up), targets Android 8+ (`minSdkVersion 26`)
- Folder structure from `02_ARCHITECTURE.md` exists under `lib/`
- `core/config.dart` has `const bool useMocks = true;`
- `core/theme.dart` has app colour scheme, text styles (large, plain language)
- Provider set up in `main.dart` with `MultiProvider`
- Named route navigation configured
- `analysis_options.yaml` has strict lint rules
- `flutter analyze` clean
- App launches and shows a placeholder home screen
**Status:** done

---

### T-02: Mock Layer
**Covers:** FR-3.2–3.9, FR-4.1–4.5, FR-6.3, FR-7.1–7.2
**Depends on:** T-01
**Done when:**
- `WearableSource` interface defined with sensor data stream + connection state stream
- `MockWearableSource` emits scripted scenarios: normal calm data, stress spikes (HR > 100, stress_prob > 0.85), SpO2 drops (< 95%), simulated disconnects/reconnects
- `AuthRepository` interface + `MockAuthRepository` (login with hardcoded user, logout, forgot-password stub)
- `DataRepository` interface + `MockDataRepository` (returns canned classifications, 24h history, alerts)
- `LocalStore` interface + implementation (sqflite-based offline queue)
- `PacketParser` interface defined (raw PPG byte parser interface)
- `SensorPacket` model created
- All interfaces importable from a single barrel file
- `flutter analyze` clean
**Status:** done

---

### T-03: Auth Screens
**Covers:** FR-1.1, FR-1.6, NFR-5.4
**Depends on:** T-02
**Done when:**
- Login screen: email + password fields, login button, 
- Logout accessible from settings/menu
- Login via `MockAuthRepository` succeeds with test credentials
- Session state managed via Provider; unauthenticated user cannot reach home screen
- UI uses plain language, large touch targets (NFR-4.1)
- JWT token saved via `flutter_secure_storage`
- `flutter analyze` clean
**Status:** done

---

### T-04: Home Screen
**Covers:** FR-7.1, FR-7.2, FR-7.5, FR-6.3, NFR-4.1, NFR-4.2, NFR-4.4
**Depends on:** T-02, T-03
**Done when:**
- State card shows Calm or Stressed with colour + icon + text (never colour alone)
- Live HR value displayed with heart icon
- Live SpO2 value displayed (separate from ML state)
- Wellness-tool disclaimer visible ("This is a wellness tool, not a medical diagnosis")
- Current state reachable within two taps of app launch (NFR-4.2)
- Data driven by `MockWearableSource` stream via Provider
- `flutter analyze` clean
**Status:** done

---

### T-05: Connection UI
**Covers:** FR-3.6, FR-3.7, FR-3.9, NFR-2.1
**Depends on:** T-02, T-04
**Done when:**
- Three visual states displayed: Connected (green + icon + "Connected") / Reconnecting (amber + spinner + "Reconnecting…") / Disconnected (red + icon + "Disconnected")
- Colour + icon + text used (NFR-4.4)
- Failure messages shown when wearable not found or connection fails (FR-3.9)
- Connection state driven by `MockWearableSource` connection stream
- Auto-reconnect behaviour simulated in mock (disconnect → reconnecting → connected cycle)
- `flutter analyze` clean
**Status:** done

---

### T-06: Sustained Stress Notification Display
**Covers:** FR-6.2, FR-9.1 (app-side display)
**Depends on:** T-04
**Done when:**
- Passive alert card displays on Home Screen when backend reports sustained Stressed state (D-24)
- No haptic/vibration alerts to prevent disturbing worker during shift
- SpO2 low alert displayed when SpO2 < 95% (separate from stress state)
- Clear, plain language wellness message & recommendation card (NFR-4.1)
- `flutter analyze` clean
**Status:** done

---

### T-07: Self-Report Check-in
**Covers:** FR-8.1, FR-8.2, FR-8.3, FR-8.4, NFR-4.3
**Depends on:** T-02, T-03
**Done when:**
- Check-in screen with 3 tap-based questions: feeling (Fine/Tired/Unwell), pain (No/Mild/Severe), stress (Low/Medium/High)
- No typing required — buttons/chips only
- Completable in under one minute (NFR-4.3)
- Triggers once per shift (mock) + available on-demand from menu
- Submission stored via `MockDataRepository`
- `flutter analyze` clean
**Status:** not started

---

### T-08: 24-Hour State History
**Covers:** FR-7.6
**Depends on:** T-02, T-04
**Done when:**
- Screen shows list or timeline of classification results for the last 24 hours
- Each entry shows timestamp, state (Calm/Stressed) with colour + icon + text
- Data from `MockDataRepository`
- `flutter analyze` clean
**Status:** not started

---

### T-09: Offline Queue and Sync
**Covers:** FR-4.4, FR-4.5, NFR-2.2, NFR-2.4
**Depends on:** T-02
**Done when:**
- Sensor data queued in `LocalStore` (sqflite) when network unavailable
- Queue retains data for at least 8 hours (one shift) (~17 MB per 8h shift)
- Sync to backend triggered when connectivity restored (mock: simulated)
- Malformed packets discarded without crashing (NFR-2.4) — tested with garbage input
- `flutter analyze` clean
**Status:** not started

---

### T-10: Real BLE Layer
**Covers:** FR-3.1–3.9, FR-4.1, NFR-7.3, NFR-7.4, NFR-9.1
**Depends on:** T-02, T-05
**Done when:**
- `BleWearableSource` implements `WearableSource` using `flutter_blue_plus`
- Runtime permissions requested (BT scan, BT connect, location)
- GPS-on check on Android
- Scan by Service UUID only
- Subscribe to notification characteristics
- MTU request after connect
- Auto-reconnect every 5 seconds on disconnect
- Foreground service via `flutter_foreground_task`
- `PacketParser` implementation for raw PPG at ~100 Hz format
- Switched in when `USE_MOCKS = false`
- `flutter analyze` clean
**Status:** 🚫 BLOCKED — vendor has not provided Service UUID, characteristic UUIDs. See `05_BLE_SPEC.md` OPEN/UNRESOLVED.

---

### T-11: Real API Integration
**Covers:** FR-1.1, FR-4.3, FR-4.5, FR-7.1, FR-7.6, FR-8.4, FR-9.1
**Depends on:** T-02
**Done when:**
- `ApiAuthRepository` and `ApiDataRepository` implement interfaces using `http` package
- All assumed API endpoints (D-10 through D-16) replaced with real contract
- JWT token stored securely (`flutter_secure_storage`) and sent with `Authorization: Bearer <token>`
- Error handling for network failures, 401/403, timeouts
- Switched in when `USE_MOCKS = false`
- `flutter analyze` clean
**Status:** 🚫 BLOCKED — backend API contract does not exist yet.

---

### T-12: Polish and Testing
**Covers:** NFR-7.1, NFR-9.3, all features
**Depends on:** T-01 through T-09
**Done when:**
- Widget tests for key screens (home, auth, check-in)
- Unit tests for `PacketParser`, `LocalStore`, models
- Android 8.0+ minimum verified (`minSdkVersion 26`)
- FYP demo screenshots captured
- README updated with setup instructions
- `flutter analyze` clean, all tests pass
**Status:** not started

---

## Known Issues & Blockers

| Issue | Blocked tasks | Resolution needed from |
|---|---|---|
| Vendor has not provided BLE Service UUID or characteristic UUIDs | T-10 | Hardware / embedded team |
| Backend API contract does not exist | T-11 | Backend team |

## Open Questions for Saud

*(All initial 5 open questions resolved by Saud on 2026-10-08 — see `06_DECISIONS.md` D-09, D-10, D-19, D-20, D-22)*
