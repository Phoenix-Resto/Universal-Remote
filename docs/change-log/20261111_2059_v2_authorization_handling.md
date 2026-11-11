# V2 — Runnable pairing and one-command attempt (historical)

- **Recorded:** 2026-11-11, 20:58 IST. Retrospective entry; original experiment timestamp was not recorded.
- **Classification:** Logical / connection and authorization behavior.
- **Version status:** Failed in the observed initial testing.
- **Historical source:** `history.md` → `Second Trail - failed`.
- **Changed code at the time:** Standalone `main.dart` experiment; currently represented in `history.md`.

## Intent and implementation

Upgraded the initial sketch to a runnable `main()` with `dart:async`, a connection timeout, `Completer<bool>` pairing gate, `ms.channel.connect` and `ms.channel.unauthorized` handling, a single `KEY_VOLUP` send after authorization, and socket cleanup. The code preserved in `history.md` specifies the encrypted URL `wss://<tv-ip>:8002/...` but **does not** supply a custom TLS client for the TV's untrusted/self-signed certificate.

## Outcome / verification

**No successful authorization or volume change from this version.** The observed troubleshooting sequence included:

1. A plain `ws://<tv-ip>:8001` connection succeeded at the transport layer, but the TV showed no Allow/Deny prompt and the program reported `TV did not authorize this connection.` The specific closing/denial event was not captured in the screenshot, so the underlying reason is unconfirmed.
2. Changing only the port to 8002 while retaining `ws://` produced `HttpException: Connection closed before full header was received`; this attempted plaintext WebSocket against a TLS endpoint.
3. Using `wss://<tv-ip>:8002` without a certificate exception produced `HandshakeException: CERTIFICATE_VERIFY_FAILED: self signed certificate in certificate chain`.

The preserved V2 source reflects the secure-protocol attempt; the earlier ad-hoc URL edits were debugging steps, not separate archived source versions.

## Reasons for change

Use `wss://` on port 8002 and pass a **TV-endpoint-scoped** `HttpClient.badCertificateCallback` in the local development prototype, so the untrusted TV certificate does not stop the pairing handshake. Continue waiting for explicit authorization before transmitting.

## Limitations

No trusted identity verification for a self-signed certificate; no persisted token; no interactive remote controls. See the solving-mistakes report for the definitive resolution and security follow-up.
