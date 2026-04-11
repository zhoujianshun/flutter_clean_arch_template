# App Resources — Launcher Icons & Native Splash

This document covers two code-generation tools that produce **platform-native** assets from a single configuration file. They are not runtime dependencies — they modify project files during development and the generated resources are committed to version control.

## flutter_launcher_icons

> **What it does**: Generates platform-specific app launcher icons (Android adaptive icons, iOS icon sets, web favicons, macOS/Windows icons) from a single source image.

### Why use it?

Without this tool you would need to manually create and place dozens of icon variants across `android/app/src/main/res/mipmap-*`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/`, etc. The tool automates all of that from one high-resolution PNG.

### Configuration

The configuration file lives at the project root: **`flutter_launcher_icons.yaml`**.

Key parameters:

| Parameter | Description |
|-----------|-------------|
| `image_path` | Path to the source image (recommended: 1024×1024 PNG, no transparency) |
| `android` | Set to a launcher name string (e.g. `'launcher_icon'`) or `true` to generate Android icons |
| `min_sdk_android` | Minimum Android SDK level (default 21) |
| `adaptive_icon_background` | Background color or image for Android adaptive icons (Android 8+) |
| `adaptive_icon_foreground` | Foreground image for adaptive icons |
| `ios` | `true` to generate iOS icons |
| `remove_alpha_ios` | `true` to remove alpha channel (required by App Store) |
| `web` / `macos` / `windows` | Platform-specific sections (see config file comments) |

### Usage

```bash
# Using justfile
just gen-icon

# Manual command
flutter pub run flutter_launcher_icons -f flutter_launcher_icons.yaml
```

### What it generates

| Platform | Output |
|----------|--------|
| Android | `android/app/src/main/res/mipmap-*/launcher_icon.png` + adaptive icon XML |
| iOS | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (all required sizes) |
| Web | `web/icons/` + updates `web/manifest.json` |
| macOS | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` |

### Workflow

1. Place your source icon at `assets/icon/app_icon.png` (1024×1024 PNG).
2. Edit `flutter_launcher_icons.yaml` if needed (e.g. enable adaptive icon, web, macOS).
3. Run `just gen-icon`.
4. Verify the generated icons by building and running the app.
5. Commit the generated files.

### Tips

- **Android adaptive icons**: Provide separate foreground/background images for a modern look on Android 8+. The foreground should have transparent padding (safe zone is 66% of the canvas).
- **iOS**: The App Store requires no alpha channel — keep `remove_alpha_ios: true`.
- **Re-run after changes**: The tool overwrites previous output, so you can iterate freely.

---

## flutter_native_splash

> **What it does**: Generates native splash screen resources for Android, iOS, and Web that display **before** Flutter renders its first frame. This replaces the default white screen with your brand image/color.

### Why use it?

Flutter apps have a brief "cold start" period where native platform code loads the Dart VM and framework. During this time, the OS shows a native splash screen. Without customization, it's a blank white screen. This tool lets you control what users see during that window.

### How it works in the template

The template uses a **preserve + remove** pattern:

```text
App Launch
  │
  ▼
┌──────────────────────────┐
│  Native splash (generated │ ← Controlled by flutter_native_splash.yaml
│  by flutter_native_splash)│
└──────────┬───────────────┘
           │  FlutterNativeSplash.preserve(widgetsBinding)
           │  (called in AppInitializer.initialize)
           ▼
┌──────────────────────────┐
│  App initialization       │ ← Load env, logger, DI, etc.
│  (keeps native splash     │
│   visible during setup)   │
└──────────┬───────────────┘
           │  FlutterNativeSplash.remove()
           │  (called in SplashPage after init completes)
           ▼
┌──────────────────────────┐
│  Flutter SplashPage       │ ← Your Dart-rendered splash/transition
│  → navigates to Login     │
│    or AppShell             │
└──────────────────────────┘
```

**Code references:**

- `lib/core/initializers/app_initializer.dart` — calls `FlutterNativeSplash.preserve()` to keep the native splash visible during async initialization.
- `lib/features/app/presentation/pages/splash_page/splash_page.dart` — calls `FlutterNativeSplash.remove()` after initialization completes, then navigates.

### Configuration

The configuration file lives at the project root: **`flutter_native_splash.yaml`**.

Key parameters:

| Parameter | Description |
|-----------|-------------|
| `color` | Solid background color (hex, e.g. `'#ffffff'`) |
| `background_image` | Alternative: background PNG (stretched to fill) |
| `image` | Optional: centered logo image (PNG, sized for 4x density) |
| `branding` | Optional: branding image at bottom of screen |
| `color_dark` / `image_dark` | Dark mode variants |
| `android_12` | Separate config for Android 12+ (uses different splash API) |
| `android` / `ios` / `web` | Set `false` to skip a platform |
| `fullscreen` | `true` to hide the notification bar |

### Usage

```bash
# Generate splash screens
just gen-splash

# Manual command
dart run flutter_native_splash:create --path=flutter_native_splash.yaml

# Restore Flutter default (remove customization)
dart run flutter_native_splash:remove
```

### What it generates

| Platform | Output |
|----------|--------|
| Android (<12) | `android/app/src/main/res/drawable/` + `values/` + `styles.xml` modifications |
| Android (12+) | `android/app/src/main/res/values-v31/` + `drawable-v31/` |
| iOS | `ios/Runner/Base.lproj/LaunchScreen.storyboard` + image assets |
| Web | `web/splash/` resources + `web/index.html` modifications |

### Workflow

1. Prepare your splash assets:
   - Background: solid color OR a full-screen PNG
   - Logo (optional): centered PNG, sized for 4x pixel density
   - Android 12 icon (optional): 960×960 or 1152×1152 PNG
2. Edit `flutter_native_splash.yaml`.
3. Run `just gen-splash`.
4. Test on a real device (simulators may skip the splash).
5. Commit the generated files.

### Tips

- **Android 12+ is different**: It uses a system-level splash API with a centered circular-cropped icon. Configure the `android_12` section separately.
- **preserve/remove pattern**: Always call `FlutterNativeSplash.preserve()` early in `main()` and `FlutterNativeSplash.remove()` when your app is ready. The template already does this.
- **Dark mode**: Provide `_dark` variants for a polished experience on dark-mode devices.
- **Re-run after changes**: Generated files are overwritten each time; iterate freely.

---

## Quick Reference

| Task | Command |
|------|---------|
| Generate launcher icons | `just gen-icon` |
| Generate native splash | `just gen-splash` |
| Remove native splash customization | `dart run flutter_native_splash:remove` |
| Regenerate all code (Riverpod, Freezed, etc.) | `just gen` |

### Asset Directory Structure

```text
assets/
├── env/                  # Environment files (.env.*)
├── icon/                 # Launcher icon source images
│   └── app_icon.png      # 1024x1024 source icon
└── splash/               # Splash screen source images
    └── splash_logo.png   # Optional centered logo
```
