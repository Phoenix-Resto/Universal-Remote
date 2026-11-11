# Fix dark-theme startup assertion

- **Recorded:** 2026-11-11 22:35 IST
- **Classification:** Runtime startup fix (theme configuration)
- **Status:** Patch prepared; device verification pending

## Symptom

Flutter startup failed while building `UniversalRemoteApp` with:
`ThemeData.brightness does not match ColorScheme.brightness`.

## Root cause

`ThemeData(brightness: Brightness.dark)` was paired with `ColorScheme.fromSeed(...)` using its default light brightness.

## Change

- `lib/main.dart`: explicitly set `brightness: Brightness.dark` in the seeded `ColorScheme`, consistent with the enclosing `ThemeData`.
- No modifications to TV pairing, transport, tokens, commands, or layout.

## Verification

- Source-level review confirms matching theme brightness configurations.
- Flutter SDK is unavailable in this patch-authoring environment; `flutter analyze`, `flutter test` and on-device startup are **not yet run**.
- User verification: overlay patch, run `flutter run`, verify UI appears without a red error screen, then connect to TV and test volume controls.
