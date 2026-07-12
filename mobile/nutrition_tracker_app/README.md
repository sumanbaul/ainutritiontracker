# NutriLens mobile

Flutter client for the Android-first NutriLens experience. From the repository root, run `./scripts/run-mobile.ps1`; it detects the connected device and API address and supplies the Flutter development configuration automatically.

Use `flutter analyze`, `flutter test`, and `flutter build apk --debug` for direct mobile verification. Cleartext HTTP is development-only; production must use HTTPS. See [local development](../../docs/development.md) and [architecture](../../docs/architecture.md).
