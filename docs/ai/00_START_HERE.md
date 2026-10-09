# 00 — START HERE (Constitution)

## Project Summary

**HealthNest** is an employee wellbeing monitoring system for industrial workers.
A custom ESP32 wristband streams sensor data over BLE to a Flutter mobile app,
which forwards it to a Flask backend for ML-based stress classification.
**Your scope is the Flutter mobile app ONLY.** Backend, ML model, wristband firmware,
and React web dashboard are owned by others or do not exist yet.

## Reading Order

1. **Always read first:** this file (`00_START_HERE.md`) + `PROGRESS.md`.
2. **Read other `/docs/ai/` files ONLY when relevant** to the task you are working on.
3. **Read `/docs/orignal/` ONLY if** a `/docs/ai/` file is ambiguous (note: folder is spelled `orignal`).

## File Map

| File | Read when… |
|---|---|
| `01_PROJECT_BRIEF.md` | You need project context, user roles, or data flow |
| `02_ARCHITECTURE.md` | You are creating/modifying code structure, interfaces, or packages |
| `03_REQUIREMENTS_APP.md` | You need the exact requirement ID, wording, or priority for a feature |
| `04_DB_SCHEMA.md` | You are building data models or repository methods |
| `05_BLE_SPEC.md` | You are working on wearable connection, BLE, or the packet parser |
| `06_DECISIONS.md` | You are making or reviewing a design decision |
| `07_UI_GUIDE.md` | You are building or changing any screen |
| `PROGRESS.md` | Always (task list, blockers, open questions) |
| `HANDOFF_LOG.md` | At session start (context from previous agent) and at session end (write your entry) |

## Mandatory Rules for Every Agent

| # | Rule |
|---|---|
| a | **Never invent** requirements, endpoints, UUIDs, packet formats, or features. If it is not in the docs, ask Saud. |
| b | Work on **ONE task** from `PROGRESS.md` at a time, in order. Small commits: `"T-XX: short description"`. |
| c | **Never remove or bypass the mock layer.** Real BLE/API plug in behind the same interfaces. Switch only via `USE_MOCKS` flag in `core/config.dart`. |
| d | Mobile app shows **exactly two ML states: Calm and Stressed.** SpO2 is displayed and alerted separately — never part of ML state. |
| e | State must **never be conveyed by colour alone**: always colour + icon + text (NFR-4.4). |
| f | **Plain language, large icons**, low-digital-literacy UI (NFR-4.1). |
| g | The app is a **wellness tool, not medical diagnosis** (FR-7.5). The disclaimer notice must be visible in the UI. |
| h | **No secrets, API keys, or real credentials** in the repo. |
| i | Keep **BLE logic strictly separate** from UI (NFR-9.1). |
| j | **Before coding**: state in 3 lines what you understood. **After coding**: run `flutter analyze` and fix issues; run tests if they exist. |
| k | If you make a **design decision**, record it in `06_DECISIONS.md`. |
| l | When the session ends or Saud says "wrap up": **update `PROGRESS.md`** and append to `HANDOFF_LOG.md`. If tokens are running low, do this FIRST. |
| m | **Before building or changing any screen, read `07_UI_GUIDE.md` and look at the matching file in `ui_design/`. Follow its layout and style. Requirements win any conflict.** |

## Definition of Done (for any task)

- [ ] Acceptance criteria from `PROGRESS.md` are met
- [ ] `flutter analyze` is clean (zero issues)
- [ ] App runs with `USE_MOCKS = true`
- [ ] `PROGRESS.md` updated (status, any new blockers/questions)
- [ ] Changes committed with message format `T-XX: short description`
