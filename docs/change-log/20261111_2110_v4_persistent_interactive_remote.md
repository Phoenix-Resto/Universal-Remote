# V4 — Working Samsung CLI remote with persisted pairing (historical)

- **Recorded:** 2026-11-11, 20:58 IST, retrospectively; original code timestamp was not retained.
- **Type:** Logical change (connectivity, token lifecycle, command input)
- **Status:** User-verified working against Samsung UA32M4300
- **Source:** Existing repository root `main.dart` (preserved; remains CLI prototype)

## Why this version was needed

V3 proved secure connection on `wss://<tv-ip>:8002`, TV authorization, receipt of `ms.channel.connect` and submission of a volume key. But the TV's token was not saved, and the program terminated after a single command. A practical remote requires reusable pairing and multiple commands per session.

## Code changes made in V4

1. Retained the secure WSS endpoint and TV-host/port-scoped development-only self-signed certificate exception.
2. Added `loadToken()` / `saveToken()` to persist `data.token` in `.secrets/samsung_token.txt` and load it at startup.
3. Reused the token through `token` in the WebSocket connection query parameters, alongside the base64-encoded app name.
4. Kept the authorized socket open for a line-oriented terminal session; translated short aliases (`vol+`, `vol-`, `mute`, `home`, `up`, `ok`, and others) into Samsung `KEY_*` commands.
5. Sent `ms.remote.control` / `SendRemoteKey` with `Cmd=Click`, checked the socket before sending, and cleaned up on exit.
6. Excluded `.secrets/` from source control; the development token file is plaintext and must never be distributed.

## Outcome / evidence

The user reported: **"All works, connected fine, remote working, reconnected without asking permission again."** This confirms the real TV responded to interactive remote actions and that token reuse avoided another approval popup on a subsequent session.

This is a **real-device user test**, not an automated test run in this repository. No production security audit or cross-model compatibility testing has been performed. TV wake-on-LAN / turning the TV on from standby has not been verified.

## Files / preservation

- `main.dart`: existing V4 implementation (left unchanged as the working regression reference).
- `.gitignore`: `.secrets/` is excluded from Git.
- `docs/solving-mistakes/20261111_2058_samsung_websocket_pairing_resolution.md`: full V1–V4 cause/solution narrative.

## Next phase

Implement a separate Flutter GUI in `lib/`, keeping the root CLI code intact. Android pairing state is stored independently in platform secure storage; the CLI's local token file is intentionally not bundled into the app.
