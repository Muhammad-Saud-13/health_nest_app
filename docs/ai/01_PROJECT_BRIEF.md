# 01 — Project Brief

## What is HealthNest?

HealthNest is an employee wellbeing monitoring system for industrial environments. A custom ESP32 wristband (MAX30102 PPG + MPU6050 accelerometer + optional skin temp sensor) collects physiological data. The system classifies each worker's state as **Calm** or **Stressed** using a server-side Random Forest model trained on the WESAD dataset, and monitors **SpO2** separately via a rule-based threshold (< 95% = critical alert).

## Users

| Role | Platform | Scope |
|---|---|---|
| **Employee** | Flutter mobile app | Views own state, HR, SpO2; receives alerts; does self-report check-ins |
| **HR / Admin** | React web dashboard (not our scope) | Registers employees, views department analytics, acknowledges alerts |

## What the Mobile App Does

- Authenticates the employee (email + password)
- Connects to the wristband via BLE and streams sensor data
- Forwards sensor data to the backend server
- Displays the employee's current ML state (Calm / Stressed) with colour + icon + text
- Displays live Heart Rate and live SpO2
- Shows stress alerts (vibration + on-screen) when stress probability > configurable threshold (default 85%)
- Shows SpO2 critical alert when SpO2 < 95%
- Offers a 60-second guided breathing exercise after a stress alert
- Provides a self-report check-in (3 tap-based questions, once per shift + on-demand)
- Shows 24-hour state history
- Queues data locally when offline, syncs when reconnected
- Shows a wellness-tool disclaimer (not medical diagnosis)

## What the Mobile App Does NOT Do

- ❌ Run ML inference on-device — classification happens on the backend
- ❌ Provide medical diagnosis — it is a wellness tool only
- ❌ Display a management dashboard — that is the React web app
- ❌ Support multiple organizations — single-org for FYP
- ❌ Enforce device ownership — one band is reused in demo
- ❌ Access the database directly — all data goes through a backend API

## Demo Assumptions

- **Single organization** — no multi-tenancy
- **One wristband reused** across demo subjects
- **Data ownership** = the employee currently logged into the mobile app
- Employee accounts are **pre-created by HR** on the web dashboard

## End-to-End Data Flow

```
Wearable (ESP32)
    │ BLE (sensor packets)
    ▼
Flutter Mobile App
    │ HTTPS / REST
    ▼
Flask Backend Server
    │ Feature extraction + ML predict
    ▼
PostgreSQL (Supabase)
    │
    ▼
React Web Dashboard  +  Alerts (push to app / dashboard)
```

The mobile app sits between the wearable and the backend. It is a **relay + display + local UX layer**, not a processing engine.
