# Phase 14: authentication, offline replay, storage, and release hardening

## Authentication

Production uses short-lived JWT access tokens and rotating opaque refresh tokens. Register or sign in through `/api/auth/register` and `/api/auth/login`; refresh through `/api/auth/refresh`; revoke through `/api/auth/logout`. Tokens are stored only in platform secure storage. The API derives ownership from the validated `sub` claim. `X-Development-User-Id` is retained only in Development/Testing and is removed from untrusted production requests.

Set these through a production secret manager, never source control:

- `Authentication__SigningKey` (at least 32 random characters)
- `ConnectionStrings__DefaultConnection`
- selected meal-vision provider key
- S3-compatible image credentials, only when `MealAnalysis__Provider=S3`

## Offline replay and conflicts

The Drift queue is versioned and user scoped. Records contain operation and entity identifiers, JSON payload, idempotency key, dependency group, retry count, next retry time, server version, status, and error. Replay is FIFO, connectivity aware, stops behind a failing dependency, uses bounded exponential backoff, and marks HTTP 409 as `Conflict`. UI choices are server version, keep local changes after refresh, or review differences. Image uploads are never queued implicitly.

Recipe and reminder updates accept `expectedVersion`; stale writes return ProblemDetails 409 with `code=concurrency_conflict` and `serverVersion`. Hydration and fasting retain client operation IDs. Further mutation endpoints should adopt the same contract before enabling their queue adapters.

## Private image storage

Development uses `MealAnalysis:Provider=Local`. Self-hosted Production may also use protected Local storage only when `MealAnalysis__AllowLocalInProduction=true`; otherwise it fails closed at startup. S3-compatible private storage remains optional. The server validates storage keys, MIME type, and size, and preserves `/api/meals/{mealId}/image` as the only client contract. Configure `RetentionDays`, `DeleteOnMealDelete`, `MaximumImageBytes`, and `AllowedMimeTypes`. Account/meal deletion attempts object deletion; private orphan cleanup should periodically delete objects older than the configured retention that have no database record.

## Android toolchain

Flutter detects SDK 36.0.0 and accepted licenses; the connected Redmi is API 35. Forced builds confirmed corrupt API-35 and API-36 `android.jar` files, including a newly downloaded API-35 revision. To retain a reproducible build without blindly upgrading Flutter/Gradle, `sqlite3_flutter_libs` is pinned to the API-34-compatible 0.5.24 release and `compileSdk` uses the healthy API 34 platform. Repair the newer platforms when Google's repository/download path is healthy:

```powershell
$env:JAVA_HOME='G:\Program Files\Android\Android Studio\jbr'
& 'G:\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat' --list_installed
& 'G:\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat' --licenses
# Only after a confirmed android-35 corruption:
& 'G:\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat' --uninstall 'platforms;android-35'
& 'G:\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat' 'platforms;android-35' 'build-tools;35.0.0' 'platform-tools'
flutter doctor -v
```

## Release

Copy `android/key.properties.example` to the ignored `android/key.properties` and point it to a separately stored upload key. Release no longer uses the debug signing key. Production Android does not opt into cleartext traffic. Build with a production HTTPS URL:

```powershell
flutter build appbundle --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://api.example.invalid
```

Archive the AAB, native symbols, and `mapping.txt` from the build outputs. Replace the privacy-policy placeholder before store submission. Crash reporting remains intentionally unconfigured until a vendor and privacy policy are approved.

## Verification

Run `scripts/test-integration.ps1` with a dedicated PostgreSQL test connection. CI provisions PostgreSQL 17, applies migrations, then runs all backend and Flutter checks. `scripts/verify-meal-vision.ps1` checks configuration without a provider call; paid analysis requires the explicit switch.
