# Incident report — Samsung UA32M4300 network remote pairing and TLS failures

- **Recorded:** 2026-11-11, 20:58 IST (retrospective; original test timestamps unavailable)
- **Classification:** Significant diagnosed logical/networking issue
- **Status:** Resolved for the observed local Dart prototype; production security and resilience remain open
- **Affected target:** Samsung UA32M4300 (Tizen), home LAN, Dart WebSocket remote
- **Evidence:** User's PowerShell/terminal results and confirmed TV approval/control; `history.md` holds V1–V3 code, root `main.dart` is the later working V4

## Objective and baseline

Control a Samsung UA32M4300 through Wi-Fi without an IR blaster. The device information endpoint `http://<tv-ip>:8001/api/v2/` returned Samsung SmartTV / Tizen metadata and advertised `remote_available=true` and `TokenAuthSupport=true`. Both TCP ports 8001 and 8002 passed `Test-NetConnection` from the developer PC. This established LAN reachability and advertised API capability, **not** authorization or working button execution.

## Symptoms and evidence, in order

| Stage | What was tried | Observed result | Interpretation |
| --- | --- | --- | --- |
| V1 — `history.md` First Trail | WebSocket sketch to `ws://<tv-ip>:8001`, command assembled but send commented | No runnable complete remote test | Missing entry point, authorization gating and actual send |
| V2 — initial runtime test | Plain `ws://<tv-ip>:8001` with authorization event waiting | `WebSocket connected`, then `TV did not authorize this connection`; no TV popup | Transport was reachable, but authorization did not complete; exact event/reason not captured |
| V2 — ad-hoc port swap | Changed `8001` to `8002` **without** changing `ws://` | `HttpException: Connection closed before full header was received` | TLS port cannot accept the plaintext handshake |
| V2 — secure URL | `wss://<tv-ip>:8002` using default TLS verification | `HandshakeException: CERTIFICATE_VERIFY_FAILED: self signed certificate in certificate chain` | TV certificate was not trusted by default client |
| V3 — TLS exception scoped to TV endpoint | `wss://<tv-ip>:8002` with a custom `HttpClient.badCertificateCallback` matching TV host and port | Secure WebSocket connected; TV showed Allow prompt; `ms.channel.connect` received; token present; `KEY_VOLUP` submitted | Pairing and command dispatch succeeded |
| V4 — current root `main.dart` | Persist token locally, reconnect with `token` query parameter, keep an interactive command session | User reported keys worked and reconnection required **no** further approval | Functional control and token reuse were validated by the user |

**Documentation distinction:** The version labeled Second Trail in `history.md` already contains `wss://...:8002` but lacks a custom TLS client. The plain `ws://...:8001`, incorrect `ws://...:8002`, and `wss://...:8002` attempts above are actual debugging observations; do not mistake them for additional archived version files. The historical source labels are `Trail` rather than `Trial` and are left unchanged.

## Root causes

1. **V1 was a skeleton, not an executable end-to-end test:** no `main()` and no transmitted key.
2. **Transport availability was confused with authorization:** successfully establishing a WebSocket/TCP connection at port 8001 did not guarantee a TV permission event or accepted control session. The precise reason for the missing popup on 8001 was not isolated.
3. **Incorrect transport scheme on 8002:** the Samsung secure service expects `wss://`, while `ws://` attempts an unencrypted HTTP upgrade handshake.
4. **TLS trust failure:** on 8002, the TV presented an untrusted/self-signed certificate chain, rejected by Dart's default certificate verification.
5. **Missing persisted pairing state in V3:** the TV returned a token, but V3 did not store or reuse it, so repeat connection behavior remained unaddressed until V4.

## Applied fix and verified outcome

- Use `wss://<tv-ip>:8002/api/v2/channels/samsung.remote.control?name=<base64-app-name>`.
- For **local development only**, connect through an `HttpClient` whose `badCertificateCallback` permits the untrusted certificate only for the configured TV host and port. This bypass is **not** sufficient TV identity verification.
- Parse the `ms.channel.connect` event and do not dispatch `ms.remote.control` commands until the TV accepts the request.
- Capture the TV-provided `data.token` without logging or publishing it. In V4, persist it in `.secrets/samsung_token.txt` and send it as the `token` query parameter on reconnect.
- Keep a WebSocket connection open and send command mappings such as `KEY_VOLUP`, `KEY_VOLDOWN`, `KEY_MUTE`, and `KEY_HOME` on terminal input.

**Observed V3 result:** `Secure WebSocket connected`, `Received event: ms.channel.connect`, `Pairing token received`, `TV authorized successfully!`, `KEY_VOLUP sent!`. The user saw and approved the connection popup.

**Observed V4 result:** The user confirmed that the remote commands operated the TV and that a later connection worked without another approval prompt. This is a user-reported device test, not a test executed in this repository environment.

## Reproduction / regression checklist

1. Keep PC and TV on the same LAN; TV powered on. Verify reachability and that the device API advertises remote capability.
2. With no usable token, start the Dart CLI and check for Samsung's approval request. Select Allow on the TV.
3. Verify the program processes `ms.channel.connect` and begins accepting remote commands.
4. Test `vol+`, `vol-`, `mute`, `home`, navigation, and `ok`; verify physical TV behavior, not just `Sent` logs.
5. Exit, relaunch and confirm the saved token is reused without a fresh TV approval.
6. Remove authorization using the TV's connected-device settings (or delete/invalidated test token), then confirm the app handles rejection/re-pairing appropriately. **Not yet recorded as tested.**
7. Ensure `.secrets/` never appears in `git status` as an untracked credential or inside release ZIPs.

## Security, limitations and prevention

- **Token:** Treat as a secret. Never commit, transmit in screenshots/logs, or include in patches; the archived uploaded ZIP contained `.secrets/samsung_token.txt`, which is excluded from the revised delivery. `.gitignore` now protects future Git staging. Anyone with a copy should not distribute it.
- **TLS:** Host/port-scoped certificate bypass still permits impostors at that endpoint. Before release, design certificate pinning or a trust-on-first-use process with appropriate verification and key rotation handling; never use a global `badCertificateCallback` that returns `true`.
- **App storage:** V4's plaintext token file is a desktop development convenience only. For Android, use platform-protected secure storage and avoid exposing token-bearing URLs.
- **Connection lifecycle:** Handle token revocation, TV IP changes (discovery), reconnect/backoff, timeout, network loss and app restart.
- **Functional gaps:** TV standby wake, all mapped key compatibility, and multiple TV models were not validated in this investigation.
- **Reporting:** Distinguish verified LAN reachability, secure WebSocket connection, authorization, command transmission and physically observed device response. Do not call a mere `socket.add` a successful button test.

## Related files

- `history.md`: full archived V1–V3 code
- `main.dart`: current user-verified V4 interactive terminal implementation
- `docs/change-log/20261111_2058_v1_initial_websocket_probe.md`
- `docs/change-log/20261111_2058_v2_authorization_handling.md`
- `docs/change-log/20261111_2058_v3_secure_pairing_success.md`
- `docs/change-log/20261111_2058_v4_persistent_interactive_remote.md`
