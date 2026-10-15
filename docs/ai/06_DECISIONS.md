# 06 — Decisions Log

Every design decision is recorded here. **Status**: LOCKED = confirmed and final, ASSUMPTION = best guess, may change.

| ID | Decision | Reason | Status |
|---|---|---|---|
| D-01 | **Flutter + Provider** for state management | Simple, well-documented, sufficient for this app's complexity. Avoids BLoC boilerplate for an FYP. | LOCKED |
| D-02 | **Mock-first architecture** with `USE_MOCKS` flag in `core/config.dart` | Real BLE hardware and backend API do not exist yet. All external dependencies hidden behind interfaces. Single flag switches between mock and real. | LOCKED |
| D-03 | **Two ML states only: Calm and Stressed** | ML Guide v2 explicitly scopes FYP-1 to 2 classes. WESAD cannot honestly support Fatigued/Overexerted. The 4-state model from FEATURES TO ADD is superseded. | LOCKED |
| D-04 | **SpO2 is separate and rule-based (< 95% = critical alert)** | ML Guide v2 §9.3: SpO2 does NOT go into the ML model. It is a parallel threshold check. | LOCKED |
| D-05 | **Single organization** — no multi-tenancy | Open Questions Q5: simpler architecture, sufficient for FYP. | LOCKED |
| D-06 | **One wristband reused in demo** — data owned by logged-in employee | Open Questions Q6: demo constraint. No device-ownership enforcement needed. | LOCKED |
| D-07 | **Scan by Service UUID** — never by MAC address | BLE doc §2.1: iOS randomises MAC. Cross-platform only works via Service UUID. | LOCKED |
| D-08 | **Android 8.0+ primary, iOS secondary** | NFR-7.1. Development and testing focus on Android. iOS support is best-effort. | LOCKED |
| D-09 | **sqflite** for local offline queue storage | Confirmed by Saud: Offline queue needs ordered inserts and deletes (~17 MB per 8-hour shift), SQL fits ordered queue operations far better than Hive. | LOCKED |
| D-10 | **Custom JWT auth from backend** with `flutter_secure_storage` | Confirmed by Saud: App uses custom JWT backend auth. App talks only to own Flask backend, never directly to Supabase. JWT tokens stored securely via `flutter_secure_storage` and sent as `Authorization: Bearer <token>`. | LOCKED |
| D-11 | **API: POST /auth/logout** | Endpoint TBD from backend team. Clears stored JWT. | ASSUMPTION |
| D-12 | **API: POST /auth/forgot-password** | Endpoint TBD from backend team. | ASSUMPTION |
| D-13 | **API: POST /sensor-data** → app sends raw/parsed sensor packets | Endpoint TBD. Payload format target is raw PPG / sensor packets. | ASSUMPTION |
| D-14 | **API: GET /classifications?user_id=X&last=24h** → returns classification history | Endpoint TBD. App polls or receives push for latest state. | ASSUMPTION |
| D-15 | **API: GET /alerts?user_id=X** → returns active alerts for the employee | Endpoint TBD. | ASSUMPTION |
| D-16 | **API: POST /checkins** → submits self-report | Endpoint TBD. | ASSUMPTION |
| D-17 | **~Stress alert vibration threshold~** | **SUPERSEDED by D-24**: Active vibration alerts deleted (FR-7.3 deleted). State is shown passively on UI cards. | LOCKED |
| D-18 | **http** package (not dio) for REST calls | Simpler, fewer dependencies, sufficient for this project. | ASSUMPTION |
| D-19 | **Raw PPG packet format (~100 Hz)** | Confirmed by Saud: Wristband transmits raw PPG byte streams for HRV feature extraction (RMSSD) on backend. | LOCKED |
| D-20 | **FR-7.4 Guided Breathing exercise deleted** | Confirmed by Saud: Priority marked "x" in source doc means requirement deleted. Omit feature from app. | LOCKED |
| D-21 | **flutter_secure_storage package for auth tokens** | Confirmed by Saud: Used to store JWT bearer tokens across app restarts. | LOCKED |
| D-22 | **Build on top of existing scaffold** | Confirmed by Saud: Keep current Flutter scaffold, package name, and platform folders. Clear only demo counter code. | LOCKED |
| D-23 | **Hybrid HR & State Processing** | Confirmed by Saud: SpO2 displayed directly on app from BLE. Live HR calculated locally via lightweight PPG peak detector for immediate UI feedback. Raw PPG/accel streamed to backend (`POST /sensor-data`), where backend computes accurate HR + HRV (RMSSD) + ML State (Calm/Stressed). | LOCKED |
| D-24 | **FR-7.3 Vibration Alert deleted — Passive Stress UI** | Confirmed by Saud: Active haptic/vibration alerts deleted to prevent worker disturbance/safety hazards during shifts. App displays state and sustained stress messages passively on app screens when viewed by the user. | LOCKED |
| D-25 | **Rename "Check-in" → "Self Report" in all UI** | Confirmed by Saud: "Check-in" is confusing because it sounds like starting a shift, making "on-demand check-in" nonsensical mid-shift. All user-facing labels now say "Self Report". Internal code identifiers (class names, file names, route names) retained as `checkin`/`CheckIn` for simplicity. | LOCKED |
