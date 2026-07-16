# Project status

Updated: 2026-07-17

The local MCP image preflight gate is implemented. New meal images are checked by the local `NutritionTracker.ImageGate.Mcp` Streamable HTTP service before provider analysis; explicit non-food/quality rejection returns 422 without storage or draft creation, while production detector failures fail closed. The MCP server uses the configured local Ollama model and does not log or persist raw image payloads.

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
# Phase 15 (MVP stabilization complete)

- Nutrition match state and nullable unknown nutrition are persisted; zero is no longer used for an unmatched item.
- Review blocks confirmation when unresolved foods remain and labels incomplete estimates explicitly.
- Self-hosted Production may use protected local retained-image storage only with an explicit opt-in. See [Phase 15](phase-15.md).
- Verified on 2026-07-13: `dotnet format`, solution build, 22 unit tests, 20 PostgreSQL integration tests, `flutter analyze`, 21 Flutter tests, and debug APK build. Migration `20260713154249_AddNutritionMatchIntegrity` was applied to the local development database.
- Focused fasting counter completed: active sessions, idempotent completion/cancellation, secure restart cache, opt-in target notification, offline pending end replay, recent history, and Progress summary visibility. It remains informational and non-medical.
- Final fasting-slice verification on 2026-07-13: `dotnet format`, zero-warning solution build, 24 unit tests, and 22 PostgreSQL integration tests passed. `dart format`, clean `flutter analyze`, 22 Flutter tests, and a debug APK build passed. The APK was reinstalled and launched on connected device `ff628a7d`; the restarted API returned `200 Healthy` and `204` for an authenticated user with no active fast.
- Device-launch reliability: `scripts/install-mobile.ps1` now resolves the same ADB-reverse/LAN route as `run-mobile.ps1` and compiles the resolved API base URL into directly installed debug APKs. This prevents the physical-device app from silently using Flutter's emulator-only `10.0.2.2` fallback.

# Food-resolution safety update (2026-07-17)

## Automatic food resolution and future validation game (in progress)

- Meal analysis now attempts conservative automatic catalog resolution and falls back to a visibly flagged AI estimate only when no safe catalog candidate is available. Estimates are private and inactive until the user confirms the meal; manual correction remains an override.
- `FoodResolutionEvent` records automatic matches, estimates, manual edits, and removals without raw images or model responses. The Flutter review page applies mutation responses directly and prevents older refreshes from replacing newer review data.
- A future, separate opt-in community validation game is documented: anonymized non-self tasks use swipe right to confirm and swipe left to reject; aggregate consensus can only create curator-review candidates.

- Resolved the false-positive resolver path where the whole meal image could cause an unrelated visible dish to be suggested for an unresolved item. Catalog resolution now starts with the user’s current search text and limits AI ranking to matching canonical names and aliases visible to that user.
- The AI resolver uses a dedicated structured response containing catalog candidate IDs, confidence, and rationale. The server rejects any ID outside its prefiltered shortlist, malformed responses, and duplicate suggestions. The mobile UI now labels results as `AI-ranked catalog match` rather than displaying model confidence as an authoritative percentage.
- When a catalog search has no defensible candidate, the user can explicitly request a nutrition estimate for the exact search text. The estimate is reviewable and editable before confirmation, carries a short-lived protected token bound to the user, meal, and item, and is never auto-saved.
- Confirming an estimate creates an unverified private custom food with `AI estimate; user reviewed` provenance and atomically resolves the draft item, recalculates nutrients/totals, and preserves confirmation eligibility rules. Search/details expose the estimate label; other users cannot see the food.
- Added integration coverage for the Pickle case, including no unrelated catalog match, reviewed estimate confirmation, owner-only search visibility, and resolved-meal state. Added Flutter model coverage for parsing reviewed estimate drafts.
- Verification: API Debug and Release builds passed with no warnings/errors; 24 unit tests, 24 Flutter tests, and `flutter analyze` passed. Live OpenAI checks returned zero catalog suggestions for `Pickle` and a review-required estimate named `Pickle`; `Curry` returned only curry-compatible suggestions and excluded `Bengali fish fry`. A debug APK was built and installed on connected device `ff628a7d`, and the Development API was restarted healthy on ADB-reversed port 5241. Interactive device navigation was not repeated because the device was at its lock/dream screen.
- PostgreSQL integration ran against the configured database: 22 tests passed and 3 pre-existing tests failed because their assertions assume a different seeded-catalog state. The new food-resolution lifecycle test passed.
