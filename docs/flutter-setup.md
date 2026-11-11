# Start the Flutter UI without Android Studio

## Overlay order (important for existing repository)

1. Keep a backup or Git commit of your current files. The existing root `main.dart` is the **Dart CLI experiment** and remains unchanged by this patch.
2. Install Flutter SDK (with `flutter`/`dart` in PATH), JDK 17+, and Android SDK **command-line tools** with platform-tools, a suitable SDK platform and build-tools. No Android Studio IDE or emulator is required; a physical Android phone is sufficient.
3. From the repository root, **before extracting the patch**, run:

   ```powershell
   flutter create --project-name universal_remote --platforms android .
   ```

   This generates missing `android/` Gradle files, icons, and Flutter boilerplate. If it creates or overwrites a `pubspec.yaml`/`lib/main.dart`, the patch in step 4 deliberately replaces those generated files. The existing repository-root `main.dart` is not `lib/main.dart`.

4. Extract the **layer-only ZIP** into the repository root, preserving relative folder paths, and allow replacement of matching files. It does not contain your original code or a full Android scaffold.
5. Run:

   ```powershell
   flutter pub get
   flutter doctor -v
   flutter devices
   flutter run -d <your-phone-device-id>
   ```

   Enable USB debugging on the phone and authorize the PC, or connect with Android wireless debugging and `adb connect`. Flutter may report missing Android licenses; accept via `flutter doctor --android-licenses` if prompted.

## First mobile test

- Put phone and TV on the same Wi-Fi LAN. Open the app, tap Settings to verify/edit the TV IP, then Connect.
- The TV may ask to authorize `UniversalRemoteFlutter`; approve it on screen.
- The phone saves its _own_ pairing token in protected platform storage. Do not transfer or publish the CLI token.
- Test `VOL+`, `VOL-`, `MUTE`, directional keys and HOME first. Verify actual TV behavior, not merely successful dispatch.
- Power-on from standby and every optional numeric/media key are unverified.

## Android build notes

- `flutter_secure_storage` 11.x requires Android minimum SDK 24 and compile SDK 37 according to its current package changelog. Check the generated `android/app/build.gradle.kts` or `build.gradle` and set `minSdk = 24` (or Groovy `minSdkVersion 24`), `compileSdk = 37` if your Flutter installation doesn't already satisfy these. Install Android SDK Platform 37 if needed.
- The patch's `AndroidManifest.xml` adds `android.permission.INTERNET` for device networking.
- The development WSS code accepts an untrusted TV certificate solely for the specified IP/port; this is unsuitable for public release without stronger device authentication.
- Don't blindly run `flutter create .` _after_ applying the patch, as it can overwrite project files. If you already have a generated Flutter project, skip step 3 and apply the patch directly.

## Patch policy

Future deliveries should contain **only changed/new files** at project-relative paths, never a replacement full-project archive. See `docsAI-rules.md`.
