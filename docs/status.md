# Project status

Updated: 2026-07-13

The backend supports PostgreSQL persistence, development identity, user profiles and targets, food search, draft meals, corrections, confirmation, dashboard summaries, and confirmed meal history. The Flutter client supports onboarding, profile/weight management, dashboard/history, camera/gallery capture, draft review, correction, and confirmation.

Real OpenAI image analysis is implemented server-side through the existing meal-vision abstraction. It requires an OpenAI key in .NET user secrets before it can be enabled. Mock analysis remains available only for deterministic testing and is visibly labeled as simulated in review.

Phase 11 adds persisted nutrient definitions/values, provenance/confidence, recipes, dietary preferences, hydration, fasting, and reminder data, together with a server-only curation-manifest guard. Phase 12 adds manual-meal drafts and an improved review summary. Exact repeat image bytes reuse the earlier persisted analysis, avoiding inconsistent repeat AI results while still creating a new editable draft.

Phase 13 is complete. The API now returns daily, weekly, and monthly nutrition/habit summaries with calorie adherence, hydration, completed fasting time, confirmed meal counts, and weight change. The mobile app includes weight trend charts, summary cards, hydration logging, completed-fast logging, server-persisted reminder preferences, and device-local daily notifications. These features include non-medical informational disclaimers.

The reference-matched UI milestone adds an adaptive editorial light/dark system, animated food-led Today and History cards, a full-image draggable meal-review sheet, showcase motion with reduced-motion support, and a safe-area-aware floating glass navigation dock. The former Habits infinite-width button constraint is fixed and covered at a 320 px large-text viewport.

UI stabilization now uses adaptive semantic action colors, full-parent `BoxFit.cover` meal imagery, a genuinely translucent blurred dock, a non-overlapping review sheet, and a sticky confirmation action. History includes a rolling 12-month GitHub-style activity grid with meal-frequency and calorie-target-adherence modes. Selecting a day uses server-provided profile-timezone UTC boundaries to retrieve exactly that day's confirmed meals.

Retained development meal images are available through `GET /api/meals/{mealId}/image`. The endpoint requires the development identity, verifies ownership, hides storage keys and paths, returns private ETags, and returns `404` for deleted, unavailable, or non-retained images. Flutter keeps only a bounded in-memory image cache.

The Phase 13 UI was refreshed as an original NutriLens design informed by modern calorie-tracker patterns: a prominent daily calorie ring, macro progress cards, quick meal/habit actions, clearer progress hierarchy, rounded elevated surfaces, and focused accent colors. No third-party branding or design assets are included.

Verified on 2026-07-13: `dotnet format`, a zero-warning backend build, 22 unit tests, `dart format`, clean `flutter analyze`, 19 Flutter tests including light/dark golden baselines, and a debug Android APK build. The integration test assembly reports 19 passing test cases, but PostgreSQL-gated test bodies require `NUTRITION_TRACKER_INTEGRATION_CONNECTION` and were not exercised in this shell. The APK is at `mobile/nutrition_tracker_app/build/app/outputs/flutter-apk/app-debug.apk`.

The configured APK was installed on the connected Redmi Note 10 Lite and launched through USB ADB reverse to `http://127.0.0.1:5241`. Device logs confirmed successful health, profile, dashboard, meal-history, capability, and authenticated meal-image requests. The refreshed Today and Progress destinations emitted no Flutter constraint, overflow, or rendering exceptions. Live API verification returned 365 activity days in `Asia/Kolkata`, and a selected date returned the same 10 confirmed meals from both the activity aggregate and filtered history query. Automated viewport and golden tests remain the authoritative coverage for the complete visual matrix.

Known limitations: temporary development identity remains in use; image retention is local development storage; real provider verification needs a user-supplied provider key or local Ollama; recipe selection in the mobile UI and full Phase 14 offline replay/conflict UX are not complete. The installed Android 35 platform is corrupt, so the verified APK uses Flutter's current compile SDK and emits a future-compatibility warning from `sqlite3_flutter_libs`. Production authentication, cloud image storage, billing, and health integrations are not implemented.
# 2026-07-13 Phase 14

Implemented rotating JWT authentication, production identity enforcement, private S3-compatible image storage, account export/deletion, recipe meal logging, secure Flutter sessions, user-scoped offline queue/replay primitives, version conflict responses, PostgreSQL CI, and Android release signing templates. External verification still requires deployment JWT/S3/AI secrets and a release upload key. See `docs/phase-14.md` for evidence and commands.

Verified on 2026-07-13: backend build 0 warnings/errors; 22 unit tests; 20 PostgreSQL integration tests against the reset dedicated `nutrition_tracker_integration_tests` database; Flutter analyze clean; 21 Flutter tests; debug APK built, installed, and launched on Redmi Note 10 Lite without a fatal/rendering exception in the sampled log. API-35/36 SDK resource tables remain corrupt locally, so the reproducible workaround pins `sqlite3_flutter_libs` 0.5.24 and compiles with healthy API 34 until the newer SDK downloads can be repaired.
# Phase 15 (in progress)

- Nutrition match state and nullable unknown nutrition are persisted; zero is no longer used for an unmatched item.
- Review blocks confirmation when unresolved foods remain and labels incomplete estimates explicitly.
- Self-hosted Production may use protected local retained-image storage only with an explicit opt-in. See [Phase 15](phase-15.md).
- Verified on 2026-07-13: `dotnet format`, solution build, 22 unit tests, 20 PostgreSQL integration tests, `flutter analyze`, 21 Flutter tests, and debug APK build. Migration `20260713154249_AddNutritionMatchIntegrity` was applied to the local development database.
