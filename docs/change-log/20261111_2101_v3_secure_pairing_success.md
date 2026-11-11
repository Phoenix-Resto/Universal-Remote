# V3 — Secure Samsung pairing and first command (historical)

- **Recorded:** 2026-11-11, 20:58 IST. Retrospective entry; original experiment timestamp was not recorded.
- **Classification:** Logical / TLS and TV authorization.
- **Version status:** Successful secure pairing and command submission.
- **Historical source:** `history.md` → `Third Trail - success`.
- **Changed code at the time:** Standalone `main.dart` experiment; now in `history.md`.

## Intent and implementation

Changed the WebSocket transport to `wss://<tv-ip>:8002/api/v2/channels/samsung.remote.control?name=<base64-name>`, created a custom `HttpClient`, and accepted an untrusted TLS certificate **only when the callback host and port matched the configured TV endpoint**. Parsed `ms.channel.connect`, observed the presence of a pairing token, waited for authorization, then sent one `KEY_VOLUP` command. Retained cleanup, error handling and a 60-second pairing timeout.

## Outcome / verification

**Confirmed by the user's real-TV terminal test:**

```text
Accepted local TV certificate for testing.
Secure WebSocket connected.
Received event: ms.channel.connect
Pairing token received.
TV authorized successfully!
KEY_VOLUP sent!
```

The TV displayed an Allow/Deny prompt; the user approved it. This proves authorized WebSocket pairing and command submission. The archived V3 output alone did **not** independently demonstrate that the volume changed; functional key execution was subsequently verified in V4 when the user reported that the terminal remote worked.

## Next logical progression (V4, current)

The current root `main.dart` adds `.secrets/samsung_token.txt` persistence, token reuse in subsequent WebSocket URLs, an interactive command map, and a long-running terminal remote session. The user confirmed volume/other remote interactions worked and reconnection did not request a fresh approval. The historical V4 implementation is now documented separately in `20261111_2058_v4_persistent_interactive_remote.md`, along with the resolution report.

## Known limitations

- Certificate acceptance is limited to the configured endpoint, but does **not** authenticate the TV's identity. Replace with a stronger trust strategy for production.
- V3 did not persist the pairing token, retain a long-running session, or discover TV addresses automatically.
- Actual key support depends on TV model/firmware. Power-on from standby over Wi-Fi is not yet validated.
