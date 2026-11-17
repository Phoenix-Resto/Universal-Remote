# V2 — Multi-device Samsung Wi-Fi onboarding

Date: 2026-11-12
Classification: Functional / navigation / persistence / device discovery

## Changes
- Replaced the single-device root screen with persistent My Devices home and Add Device navigation.
- Added Wi-Fi discovery using SSDP plus bounded private IPv4 /24 probing, with Samsung `/api/v2/` verification and manual IP fallback.
- Added waiting/failed/retryable pairing dialog and device-specific pairing token persistence.
- Added saved device details, display-only rename, disconnect/reconnect and confirmed removal (including local token deletion).
- Device identity is keyed by Samsung UUID rather than changing local IP, and existing per-IP token keys are read for migration.
- Updated handset proportions and colors to match RR URC-116 reference more closely.
- Added launcher assets for background, foreground and monochrome variants.

## Limits
- Only Samsung Wi-Fi TVs exposing the tested WebSocket API are supported; Bluetooth and IR are intentionally disabled placeholders.
- LAN scanning is user-initiated, limited to two private /24 networks and at most 20 concurrent probes. Different subnets or isolated Wi-Fi may require manual IP.
- The current TLS self-signed certificate exception verifies only destination IP and port, **not TV identity**. Must harden before release.
- Neither direct phone/TV field testing nor Flutter compile/analyze could run in the generation environment. Run `flutter analyze`, `flutter test`, and `flutter run` on the user's machine.
- Command transmission is not proof a particular TV firmware executed every key.
