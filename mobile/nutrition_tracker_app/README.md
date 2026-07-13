# NutriLens mobile

Flutter client for the Android-first NutriLens experience. From the repository root, run `./scripts/run-mobile.ps1`; it detects the connected device and API address and supplies the Flutter development configuration automatically.

Use `flutter analyze` and `flutter test` for direct mobile verification. For a directly installed development APK, run `./scripts/install-mobile.ps1` from the repository root: it applies the same USB/LAN API configuration as `run-mobile.ps1`. A bare `flutter build apk --debug` does not include a physical-device API address. Cleartext HTTP is development-only; production must use HTTPS. See [local development](../../docs/development.md) and [architecture](../../docs/architecture.md).
