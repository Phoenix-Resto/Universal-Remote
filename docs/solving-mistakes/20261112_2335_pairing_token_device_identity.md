# Pairing re-approval and hardcoded device address

## Observed
- Earlier prototype had hardcoded Samsung TV IP in the controller.
- Phone repeatedly prompted for TV access according to device testing, whereas a prior Dart CLI prototype reused its pairing token correctly.

## Root-cause hypotheses
- Earlier Flutter controller stored tokens under `samsung_token_<ip>` while later device discovery can change IP.
- Pairing events and secure-storage writes could complete asynchronously, so token persistence and reconnect behavior needed explicit ordering.
- App identity strings must remain stable across connections. Actual source of the repeated prompt is **not conclusively established** without TV-side diagnostics.

## Change
- Added `SavedDevice` UUID and device store; no default IP is needed to enter the application.
- Controller now reads a UUID-keyed token, falling back to the previous per-IP key for migration.
- On the `ms.channel.connect` event, persist token before completing pairing.
- Hold the socket connection for the remote screen and close it on explicit disconnect/remove.
- Delete local tokens on removal; TV-side authorization may need separate revocation.

## Verification plan
1. From fresh install, discover TV, accept TV permission, test Volume+ and Home.
2. Disconnect and reconnect; confirm TV does not ask permission again.
3. Kill and reopen Flutter app; confirm saved TV remains listed and reconnects without approval.
4. Renew TV DHCP IP, discover again, and check UUID-based token reuse.
5. Deny pairing, ensure Retry enabled and Cancel responsive.
6. Remove device, confirm local saved record/token deleted, then pair again.
7. Verify saved tokens never appear in logs, ZIP patch or Git commits.

## Status
Implementation completed; **device verification pending**. This is not a claim that repeated prompts are already fixed on the phone.
