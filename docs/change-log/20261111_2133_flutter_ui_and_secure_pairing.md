# Flutter UI foundation and Android secure Samsung pairing

- **Recorded:** 2026-11-11, 20:58 IST (initial development phase; no seconds in changelog names)
- **Classification:** Mixed UI and logical change (new Android control service, secure credentials, connectivity state)
- **Status:** Implemented; Flutter device build and TV test pending on user's machine

## Changed / added files

- `pubspec.yaml`: Flutter application and secure storage dependency.
- `lib/main.dart`: responsive dark-mode TV remote, editable IP, connection status, buttons and scroll-safe layout.
- `lib/services/samsung_tv_remote.dart`: WSS pairing, device-scoped token storage, authorization waiting, remote commands, socket lifecycle.
- `lib/widgets/remote_key.dart`: reusable button component that occupies flex/grid-provided space.
- `android/app/src/main/AndroidManifest.xml`: Android Internet permission and main launcher declaration.
- `docs/flutter-setup.md`: no-Android-Studio install and patch-application instructions.
- `docs/architecture/samsung-control.md`: protocol and security boundaries.
- `docs/development-guidelines.md`, `docs/AI-rules.md`: responsive UI and delta-only patch rules.

## Decisions

- Do not overwrite existing root `main.dart`: it is the verified CLI fallback.
- Use a dedicated `SamsungTvRemote` service instead of placing WebSocket logic in UI widgets.
- Store a per-IP TV pairing token via `flutter_secure_storage`, never in code, logs, repo or patch.
- Pair again from the phone once, because the desktop's development token isn't imported.
- Keep the original endpoint-specific certificate bypass **for trusted LAN development only**. It is NOT strong device identity verification and must be replaced before production release.
- TV IP defaults to the user's current value but is editable and saved locally; no automatic discovery yet.

## Verification and limitations

- Checked patch file contents, JSON-like metadata and ZIP file lists for accidental inclusion of secrets.
- The build environment used to author the patch has **no Flutter/Dart SDK**; `flutter analyze`, `flutter test`, `flutter run` and TV command execution **were not run here**.
- Built-in Samsung keys are candidate model profiles: all new UI buttons need on-TV verification, especially `KEY_CONTENTS`, `KEY_PRECH`, standby power behavior.
- Flutter SDK/Android SDK packages and generated Android scaffolding are required on the user's machine; documented in `docs/flutter-setup.md`.
