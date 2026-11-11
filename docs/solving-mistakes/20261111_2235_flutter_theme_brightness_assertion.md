# Flutter startup error: ThemeData / ColorScheme brightness mismatch

- **Recorded:** 2026-11-11 22:35 IST
- **Status:** Fix supplied; on-device regression test pending
- **Affected app:** `UniversalRemoteApp` in `lib/main.dart`

## Observed symptom

Launching the Flutter UI on an Android device displayed the red error screen:
`ThemeData.brightness does not match ColorScheme.brightness`.
The assertion was raised during `ThemeData` creation, before the remote screen could render.

## Root cause

The constructor supplied `brightness: Brightness.dark` to `ThemeData` while `ColorScheme.fromSeed(seedColor: ...)` implicitly constructed a **light** color scheme. Flutter requires both brightness values to agree.

## Resolution implemented

Set `brightness: Brightness.dark` explicitly in `ColorScheme.fromSeed`. Keep the existing dark scaffold and outer `ThemeData` unchanged.

## Regression test (pending locally)

1. Overlay the patched `lib/main.dart`.
2. Run `flutter analyze` and `flutter run` on the Android phone.
3. Confirm `UniversalRemoteApp` renders with no assertion.
4. Confirm Wi-Fi pairing and remote controls still operate.

## Prevention

Whenever `ThemeData.brightness` is set explicitly, pass the matching brightness to `ColorScheme.fromSeed` or derive both consistently from one theme mode. Include app startup in smoke tests before shipping UI patches.

## Limitations

This correction is grounded in the user's stack trace and repository source but has **not been tested with a Flutter SDK** in the patch-authoring environment; outcome should not be recorded as verified until the device test passes.
