# Remote handset controls and settings lifecycle correction

- **Date:** 2026-11-11
- **Classification:** Behavior, accessibility, tests, and lifecycle correctness (not a style-only change)
- **Files:** `lib/main.dart`, `lib/widgets/remote_key.dart`, `lib/widgets/samsung_remote_surface.dart`, `lib/widgets/tv_ip_dialog.dart`, `test/widget_test.dart`

## Changes

- Replaced the simplified control layout with a handset arrangement based on the RR URC-116 Samsung UNI-9 photo: top power/source, four numeric rows, volume/channel rockers, MEDIA.P / MENU / HDMI, tools and navigation, RETURN / EXIT, four colored function keys, P.MODE / P.SIZE / SRS / STOP, and rewind/play/pause/fast-forward.
- Added per-button Samsung key mappings with labels, icons and semantic descriptions. Some model-specific keys (especially HDMI, picture modes and media functions) are **experimental**; the device can ignore unsupported commands.
- Switched the IP settings dialog to its own `StatefulWidget`, so its input controller is disposed with the dialog route rather than immediately after the result returns.
- Replaced Flutter's stale generated `MyApp` counter widget test with tests covering the new handset and IP-dialog cancellation.
- Preserved the existing network controller, secure-token storage, connection flow and dark theme.
- Remote layout uses proportional, flexible cells and scrolling rather than fixed overall screen size.

## Verification

- Previous version: user confirmed successful phone-to-TV connection and remote control.
- User reported `_dependents.isEmpty` error after cancelling settings; this patch addresses a probable dialog-controller lifetime issue, but the provided assertion alone does not conclusively identify root cause.
- Tests and on-device verification are pending in the user's Flutter environment; run `flutter analyze`, `flutter test`, then cold restart `flutter run`.
