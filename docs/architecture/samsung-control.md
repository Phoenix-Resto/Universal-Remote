# Samsung Wi-Fi controller architecture

The verified desktop Dart controller in root `main.dart` is retained as a reference. The Flutter mobile UI lives in `lib/main.dart` and delegates all networking to `lib/services/samsung_tv_remote.dart`.

`TvRemotePage` → `SamsungTvRemote` → Dart IO `WebSocket` → Samsung UA32M4300 `wss://<TV-IP>:8002/api/v2/channels/samsung.remote.control`. A `ms.channel.connect` event confirms TV authorization; only then are UI buttons enabled. The service sends `ms.remote.control` messages with `SendRemoteKey`. No server, cloud API or IR dongle is required for this supported TV.

`flutter_secure_storage` stores a token using `samsung_token_<ip>` and the latest editable address under `samsung_tv_ip`. Reconnect adds the token to the WebSocket query. The saved CLI token is NOT copied to mobile; allow the mobile app once on the TV. The IP is not a stable device identifier; migrate to TV UUID-based discovery/storage later.

**Security debt:** The development callback accepts an invalid/self-signed certificate for the configured host/port, but a rogue host at that address can impersonate the TV. Replace this with a reviewed device trust strategy before distribution. Never print the full token-bearing WebSocket URI or bundle files under `.secrets/`. Backup/restore of Android keystore-backed credentials requires special consideration.

**Not implemented yet:** automatic discovery, reconnect/backoff, wake from standby, multi-device profiles, robust token revocation flow, persistent command queue, and end-to-end physical-TV automated testing. `sendKey` reports successful queueing, not a device acknowledgement.
