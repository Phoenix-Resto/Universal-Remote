# Launcher icons

Source: the user-approved remote-control glyph. All generated assets are PNGs; no font assets.

- `assets/icons/launcher_full.png` — square, opaque navy background, Android legacy launcher icon.
- `assets/icons/launcher_foreground.png` — transparent foreground, safe-zone padded for Android adaptive icons.
- `assets/icons/launcher_monochrome.png` — single-color transparent symbol for themed icons.

After applying patch:

```powershell
flutter pub get
dart run flutter_launcher_icons
flutter clean
flutter run
```

`flutter_launcher_icons` is a dev dependency and configuration is defined in `pubspec.yaml`. If old icons persist after installing, uninstall the debug build from your phone and rerun. No Android Studio GUI is required.
