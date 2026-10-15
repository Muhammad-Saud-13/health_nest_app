# 03 — Mobile App Requirements

Extracted from `Requirements_v1`. Only requirements relevant to the mobile app. Original IDs and priorities preserved. Priority: **M** = Must, **S** = Should.

> Requirements marked 🔌 are backend-dependent and will be **mocked** until the backend API exists.

## Authentication (FR-1)

| ID | Requirement | Pri | Mock? |
|---|---|---|---|
| FR-1.1 | Authenticate users via email and password | M | 🔌 Mock login |
| FR-1.6 | Allow users to log out; end session on logout | M | 🔌 Mock |
| FR-1.7 | Allow users to reset a forgotten password | S | 🔌 Mock (UI only) |

## Wearable Connectivity (FR-3)

| ID | Requirement | Pri | Mock? |
|---|---|---|---|
| FR-3.1 | Request Bluetooth and location permissions before scanning | M | N/A (real permissions even in mock) |
| FR-3.2 | Scan for wearable using advertised Service UUID | M | Mock stream |
| FR-3.3 | Allow employee to select and connect to the wearable | M | Mock stream |
| FR-3.4 | Receive sensor data via BLE notification characteristic | M | Mock stream |
| FR-3.5 | Receive HR (PPG), 3-axis accel, skin temp, and SpO2 | M | Mock stream |
| FR-3.6 | Display connection status: Connected / Reconnecting / Disconnected | M | Mock stream |
| FR-3.7 | Auto-reconnect on connection loss | M | Mock stream |
| FR-3.8 | Maintain wearable connection while app is in background | M | Mock (foreground service in T-10) |
| FR-3.9 | Notify employee when wearable not found or connection fails | M | Mock stream |

## Data Acquisition (FR-4) — app-side only

| ID | Requirement | Pri | Mock? |
|---|---|---|---|
| FR-4.1 | Parse raw BLE byte data into numeric sensor values | M | Mock bypasses parser |
| FR-4.2 | Associate sensor data with the logged-in employee | M | Mock |
| FR-4.3 | Transmit sensor data from app to backend | M | 🔌 Mock |
| FR-4.4 | Store sensor data locally when offline | S | Local impl |
| FR-4.5 | Sync locally stored data when connection restored | S | 🔌 Mock |

> FR-4.6 (60s buffer on backend) is **backend-only** — not implemented in the app.

## SpO2 Monitoring (FR-6) — app-side

| ID | Requirement | Pri | Mock? |
|---|---|---|---|
| FR-6.3 | Display live SpO2 value on the mobile app | S | Mock stream |

## Employee Mobile Features (FR-7)

| ID | Requirement | Pri | Mock? |
|---|---|---|---|
| FR-7.1 | Display current state (Calm/Stressed) with colour + icon + text | M | 🔌 Mock classification |
| FR-7.2 | Display live heart rate | M | Mock stream |
| FR-7.3 | ~Vibration + on-screen alert when stress probability > threshold~ | **DELETED** | Deleted (per Saud — no worker disturbance) |
| FR-7.4 | ~Offer 60-second guided breathing exercise after stress alert~ | **DELETED** | Deleted (per Saud) |
| FR-7.5 | Display wellness-tool disclaimer (not medical diagnosis) | M | Local |
| FR-7.6 | Display own state history for last 24 hours | S | 🔌 Mock |

> Note: FR-7.3 and FR-7.4 were deleted by Saud to avoid disturbing employees during work shift. Stress state is shown passively on app launch/view.

## Self-Report (FR-8)

| ID | Requirement | Pri | Mock? |
|---|---|---|---|
| FR-8.1 | Present self report once per shift | S | 🔌 Mock |
| FR-8.2 | Allow on-demand self report | S | Local trigger |
| FR-8.3 | Collect 3 tap-based answers: feeling, pain, stress level | S | Local |
| FR-8.4 | Store self report with employee ID and timestamp | S | 🔌 Mock |

> FR-8.5 (divergence flagging) is backend/dashboard-side.

## Alerts (FR-9) — app-side display

| ID | Requirement | Pri | Mock? |
|---|---|---|---|
| FR-9.1 | Generate at-risk alert for sustained Stressed state (backend generates, app displays) | M | 🔌 Mock |
| FR-9.3 | Record alerts with type, employee, timestamp, status | M | 🔌 Mock |

## Non-Functional Requirements

| ID | Requirement | Category |
|---|---|---|
| NFR-1.2 | Display stress alert within 5 sec of generation | Performance |
| NFR-2.1 | Retry lost BLE connection every 5 seconds, no user action needed | Reliability |
| NFR-2.2 | Retain locally stored data for 8-hour shift, no loss on sync | Reliability |
| NFR-2.4 | Never crash on malformed/incomplete data; discard and continue | Reliability |
| NFR-4.1 | Plain language, large icons, low digital literacy users | Usability |
| NFR-4.2 | Current state visible within two taps of launch | Usability |
| NFR-4.3 | Check-in completable in under one minute without typing | Usability |
| NFR-4.4 | Colour + text/icon to convey state (never colour alone) | Usability |
| NFR-5.1 | All data transmitted over HTTPS/TLS | Security |
| NFR-5.4 | Expire user sessions after inactivity | Security |
| NFR-6.1 | Employee data accessible only to that employee and authorised HR | Privacy |
| NFR-7.1 | Android 8.0+ primary, iOS secondary | Compatibility |
| NFR-7.3 | BLE only (no Bluetooth Classic) | Compatibility |
| NFR-7.4 | Sensor data via BLE notifications, not polled reads | Compatibility |
| NFR-9.1 | BLE connection logic separated from UI | Maintainability |
| NFR-9.3 | Source code under version control (GitHub) | Maintainability |
