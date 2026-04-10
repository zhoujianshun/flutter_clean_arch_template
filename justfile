# Flutter Clean Architecture Template - Task Runner
# Usage: just <command>

default:
    @just --list

# === Development ===

dev:
    flutter run --dart-define=ENVIRONMENT=development

staging:
    flutter run --dart-define=ENVIRONMENT=staging

prod-debug:
    flutter run --dart-define=ENVIRONMENT=production

release:
    flutter run --release --dart-define=ENVIRONMENT=production

# === Build ===

android-build-debug:
    flutter build apk --debug --target-platform android-arm64

android-build-release:
    flutter build apk --release --target-platform android-arm64

ios-build:
    flutter build ios --release

# === Code Generation ===

gen:
    dart run build_runner build --delete-conflicting-outputs

gen-watch:
    dart run build_runner watch --delete-conflicting-outputs

# === Clean & Reset ===

clean:
    flutter clean && flutter pub get

reset: clean gen

# === App Resources ===

gen-icon:
    flutter pub run flutter_launcher_icons -f flutter_launcher_icons.yaml

gen-splash:
    flutter pub run flutter_native_splash:create --path=flutter_native_splash.yaml

# === Analysis & Testing ===

analyze:
    flutter analyze --no-fatal-infos

test:
    flutter test

# === Dependencies ===

deps:
    flutter pub get

deps-upgrade:
    flutter pub upgrade

# === Devices ===

devices:
    flutter devices

# === Multi-environment run ===

run env device:
    flutter run --dart-define=ENVIRONMENT={{env}} --device-id={{device}}

# === Environment Check ===

check:
    @echo "Flutter version:"
    @flutter --version | head -1
    @echo "Environment files:"
    @ls -la assets/env/
    @echo "Dependencies:"
    @flutter pub deps --no-dev | grep -E "(flutter_dotenv|riverpod)"
