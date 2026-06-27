# qurany_app

Flutter mobile app for Qurany.

## Run the app

### 1. Start an Android emulator

The emulator must be running **before** `flutter run`. Either:

- **Android Studio** → Device Manager → start **Pixel_API_34** (or another AVD), or
- From a terminal (with `ANDROID_HOME` set):

```bash
emulator -avd Pixel_API_34
```

Wait until the emulator shows the Android home screen.

### 2. Install dependencies and run

From this directory (`flutter_app`):

```bash
flutter pub get
flutter devices
flutter run
```

`flutter devices` lists connected targets. Pick the Android emulator from that list (often `emulator-5554`).

To target a specific device:

```bash
flutter run -d emulator-5554
```

Use the exact id shown by `flutter devices` — it changes if you restart the emulator.
