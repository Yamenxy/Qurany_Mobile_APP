# qurany_app

Flutter mobile app for Qurany.

This guide covers a full **Windows** setup: Android Studio, Android SDK, Flutter, and running this project on an emulator.

---

## Prerequisites

- **Windows 10/11** (64-bit)
- **~15 GB** free disk space (Android Studio + SDK + emulator images)
- **Hardware virtualization** enabled in BIOS (Intel VT-x / AMD-V)
- **Windows Hypervisor Platform** enabled (recommended for the emulator):
  - Start → **Turn Windows features on or off**
  - Check **Windows Hypervisor Platform** → reboot

---

## 1. Install Android Studio

1. Download from [developer.android.com/studio](https://developer.android.com/studio).
2. Run the installer. You can install the app on any drive (e.g. `B:\Android Studio`).
3. On first launch, complete the setup wizard and install the **Android SDK** when prompted.

> **Note:** Android Studio can live on `B:\`, but the SDK usually defaults to:
> `C:\Users\<YourUser>\AppData\Local\Android\Sdk`

---

## 2. Install Android SDK components

Open **Android Studio → Settings → Languages & Frameworks → Android SDK**.

### SDK Platforms tab

Install at least:

| Package | Purpose |
|---------|---------|
| **Android 14.0 (API 34)** | Stable emulator target (recommended) |
| **Android SDK Platform 36** (optional) | Latest platform tools |

### SDK Tools tab

Check and apply:

- **Android SDK Build-Tools**
- **Android SDK Command-line Tools (latest)**
- **Android SDK Platform-Tools**
- **Android Emulator**
- **NDK (Side by side)** — install **NDK 30** (this project uses `30.0.14904198`)
- **CMake** (if offered)

Click **Apply** and wait for downloads to finish.

### Accept licenses

In PowerShell:

```powershell
flutter doctor --android-licenses
```

Press `y` to accept each license (after Flutter is installed in step 4).

---

## 3. Set environment variables

Open **Edit the system environment variables → Environment Variables**.

| Variable | Value |
|----------|-------|
| `ANDROID_HOME` | `C:\Users\<YourUser>\AppData\Local\Android\Sdk` |

Add these to **Path**:

```
%ANDROID_HOME%\platform-tools
%ANDROID_HOME%\emulator
%ANDROID_HOME%\cmdline-tools\latest\bin
```

Close and reopen the terminal, then verify:

```powershell
adb version
emulator -list-avds
```

---

## 4. Install Flutter

1. Download the latest **stable** Windows SDK from [docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows).
2. Extract to a folder **without spaces**, e.g. `B:\flutter`.
3. Add Flutter to **Path**:

   ```
   B:\flutter\bin
   ```

4. Verify:

   ```powershell
   flutter --version
   flutter doctor
   ```

Fix anything `flutter doctor` marks with `[!]` or `[X]` for Android development. Visual Studio is only required for **Windows desktop** apps, not Android.

---

## 5. Create an Android Virtual Device (AVD)

1. **Android Studio → Device Manager → Create Device**
2. Choose **Pixel 7** (or similar)
3. Select system image **API 34** (Google Play, x86_64) — download if needed
4. Finish, then **Start** the emulator and wait for the home screen

Or from terminal (after `ANDROID_HOME` is set):

```powershell
emulator -avd Pixel_API_34
```

If the emulator shows a **black screen**, edit the AVD → **Show Advanced Settings** → set **Graphics** to **Software - GLES 2.0**, then **Wipe Data** and start again.

---

## 6. Install this project's dependencies

From the `flutter_app` directory:

```powershell
cd "B:\Workspace\Grad Project\Qurany_Mobile_APP\flutter_app"
flutter pub get
```

### NDK (project-specific)

This app pins NDK **30.0.14904198** in `android/app/build.gradle.kts`.

If the build fails with a missing or corrupt NDK:

1. **Android Studio → SDK Manager → SDK Tools → NDK (Side by side)** → install NDK 30
2. Or delete the broken folder, e.g. `C:\Users\<YourUser>\AppData\Local\Android\Sdk\ndk\28.2.13676358`, and reinstall from SDK Manager

---

## 7. Run the app

1. **Start the emulator** (Device Manager or `emulator -avd …`).
2. Confirm Flutter sees it:

   ```powershell
   flutter devices
   ```

3. Run:

   ```powershell
   flutter pub get
   flutter run
   ```

   Or target a specific device:

   ```powershell
   flutter run -d emulator-5554
   ```

   Use the exact id from `flutter devices` — it changes if you restart the emulator.

The first Android build can take **10–15 minutes** while Gradle downloads dependencies.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `No supported devices found` | Start the emulator first; run `flutter devices` |
| `NDK did not have a source.properties` | Remove corrupt NDK folder under `%ANDROID_HOME%\ndk\`, reinstall NDK 30 in SDK Manager |
| `adb` not recognized | Set `ANDROID_HOME` and add `platform-tools` to Path |
| Emulator black screen | AVD → Graphics → **Software - GLES 2.0** → Wipe Data |
| Gradle build very slow | Normal on first run; ensure stable internet |

Run `flutter doctor -v` for a detailed environment report.
