# V1 — Initial Samsung WebSocket probe (historical)

- **Recorded:** 2026-11-11, 20:58 IST. Retrospective entry; the original experiment timestamp was not recorded.
- **Classification:** Logical / networking prototype.
- **Version status:** Incomplete; not an operational controller.
- **Historical source:** `history.md` → `First Trail - failed` (source spelling preserved).
- **Changed code at the time:** Standalone `main.dart` prototype; now archived in `history.md`.

## Intent and implementation

Prove that Dart can connect directly to a Samsung UA32M4300 over the LAN, without IR hardware or Flutter UI. The prototype built the application name using Base64, attempted the Samsung remote-control WebSocket at `ws://<tv-ip>:8001/api/v2/channels/samsung.remote.control?name=<name>`, subscribed to received messages, and constructed a `KEY_VOLUP` command object using `ms.remote.control` / `SendRemoteKey`.

## Outcome / verification

**Did not produce a working remote.** This historical snippet only declared `testSamsungTv(String ip)`; it had no `main()` entry point. It did not await an authorization event and its `socket.add(jsonEncode(command))` line remained commented out. Therefore this version could not demonstrate a volume change. Later testing independently confirmed TCP port 8001 was reachable; that does not establish that this V1 snippet completed pairing.

## Reasons for change

- Add a runnable Dart entry point and command dispatch.
- Wait for `ms.channel.connect` rather than sending commands on mere socket establishment.
- Handle unauthorized, error, timeout and disconnect cases.

## Limitations

No device discovery, no pairing token, no persistent connection, no user input or actual transmission. See `docs/solving-mistakes/20261111_2058_samsung_websocket_pairing_resolution.md` for the end-to-end investigation.
