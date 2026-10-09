# 04 — Database Schema

Source: `DATABASE SCHEMA v1`. The app does **NOT** access the database directly — it talks to a backend REST API.

## Schema Tables (compact)

| Table | Key Columns | Notes |
|---|---|---|
| `departments` | id, name | FR-2.1 |
| `plants` | id, name | FR-2.3 |
| `users` | id, employee_code, name, email, password_hash, role (HR/EMPLOYEE), department_id, plant_id, designation, is_active | FR-1 |
| `devices` | id, device_uuid, label, assigned_user_id (nullable) | Nullable — demo reuses one band |
| `shift_types` | id, plant_id, name, start_time, end_time, crosses_midnight | Template definitions |
| `shift_assignments` | id, user_id, shift_type_id, shift_date, UNIQUE(user_id, shift_date, shift_type_id) | HR assigns per day |
| `shift_sessions` | id, user_id, shift_type_id, assignment_id (nullable), department_id, shift_date, started_at, ended_at, status (ACTIVE/CLOSED/AUTO_CLOSED), start_method (MANUAL/AUTO), baseline_temp, baseline_status (PENDING/DONE/FALLBACK), baseline_window_count | Core runtime table |
| `classifications` | id, session_id, user_id, window_start, window_end, hr_mean, rmssd, sma, temp_mean, temp_delta, label, stress_prob, is_calibrating | Feature windows, not raw samples |
| `spo2_readings` | id, session_id, value, recorded_at | Violations + periodic samples |
| `alerts` | id, session_id, user_id, type (STRESS_SUSTAINED/SPO2_LOW/DIVERGENCE), created_at, status (OPEN/ACK/DISMISSED), handled_by | FR-9.3, FR-9.4 |
| `checkins` | id, session_id, user_id, kind (SHIFT_START/ON_DEMAND), feeling, pain, stress_self, submitted_at | FR-8 |

## What the App Touches

The app communicates with the backend API. It **reads or writes** these entities:

| Entity | App reads | App writes | Model class needed |
|---|---|---|---|
| `users` | Own profile (login response) | — | `User` |
| `shift_sessions` | Active session info | Start/end shift (if applicable) | `ShiftSession` |
| `classifications` | Own history (24h) | — (backend writes) | `Classification` |
| `spo2_readings` | Live value displayed | — (backend writes) | `Spo2Reading` |
| `alerts` | Own alerts | — | `Alert` |
| `checkins` | — | Submit check-in | `CheckIn` |

The app also sends **raw sensor data** to the backend (not a DB table — the backend buffers and processes it).

## API Contract: TBD

The backend API does not exist yet. Assumed endpoints are listed in `06_DECISIONS.md` as **ASSUMPTIONS** (D-10 through D-16). Do not hardcode them — they will change when the backend team provides the real contract.
