# Local development

## First-time setup

Run `./scripts/initialize-development.ps1` from PowerShell. It creates the ignored `.env.local` file and can store the OpenAI key in .NET user secrets. Secrets are never written to `.env.local`.

The API requires these user-secret values for real image analysis:

```powershell
dotnet user-secrets set "MealVision:Provider" "OpenAi" --project src/NutritionTracker.Api
dotnet user-secrets set "MealVision:OpenAi:ApiKey" "<your-key>" --project src/NutritionTracker.Api
```

Set `ConnectionStrings:DefaultConnection` in the same secret store for local PostgreSQL. Apply database migrations with `./scripts/start-api.ps1 -ApplyMigrations`.

## AI provider selection

Open **Settings → AI Analysis** in a Development build to choose an enabled provider/model for the current development identity. The choice is stored locally in Drift and is sent only as a provider/model identifier; API keys and custom URLs never leave the server.

For a free-per-image local option, install Ollama and pull a vision model, for example `ollama pull gemma3:4b`. Then configure only server-side values (user secrets or process environment): `MealVision:Ollama:Enabled=true`, `MealVision:Ollama:Endpoint=http://127.0.0.1:11434/`, and `MealVision:Provider=Ollama`. Cloud provider credentials and allowlists follow the same server-only rule. Disabled providers appear unavailable in Settings.

### Local MCP image preflight

The API preflights new meal images through the local `NutritionTracker.ImageGate.Mcp` service before calling the meal-vision provider. Start Ollama and ensure the configured local vision model is available, then start the MCP service in another terminal:

```powershell
ollama pull gemma3:4b
dotnet run --project src/NutritionTracker.ImageGate.Mcp --urls http://127.0.0.1:5250
```

The API uses `MealVision:Preflight:Endpoint=http://127.0.0.1:5250/mcp`. The service exposes `GET /health` and the MCP endpoint at `/mcp`; it does not persist image bytes. Docker Compose also provides an `image-gate` service, configured with `IMAGE_GATE_OLLAMA_ENDPOINT`, `IMAGE_GATE_OLLAMA_MODEL`, and `IMAGE_GATE_PORT`.

Production keeps `MealVision:Preflight:FailClosed=true`. Development uses the checked-in Development configuration to allow an unavailable or uncertain detector result with a warning. Explicit non-food or unacceptable-quality results still return HTTP 422 and do not create a draft or retain an image.

The Bengali/Kolkata catalog is seeded at Development startup. It contains curated, medium-confidence recipe estimates and aliases, not reproduced IFCT data. Review every AI estimate; vendor oil, sugar, portions, and recipes can materially change nutrition.

## Nutrition catalog curation

Use `scripts/curate-food-catalog.ps1` only from a trusted server or developer workstation. It validates a reviewed manifest containing a version, source, reference, and food list. Production curation additionally requires `ALLOW_NUTRILENS_PRODUCTION_CURATION=true`; it is intentionally not exposed as a mobile or public API. Never bulk-import IFCT data without written permission.

## Discover Meals plans

**What to cook** opens from the Today dashboard and creates a persisted seven-day plan from the built-in India-first/global catalog. It filters recipes against the profile diet and saved allergen/custom ingredient exclusions, supports recipe saves, and can add the planned ingredients to a deduplicated shopping list. The catalog preparation steps are reviewed facts; the current release deliberately falls back to those facts when no text-planning provider is configured and never invents nutrition or overrides safety filtering.

Migration `20260723182424_AddDiscoverMealPlanning` creates `meal_plans`, `meal_plan_entries`, `saved_catalog_recipes`, and `shopping_list_items`. Apply it before calling `/api/discover-meals/*`:

```powershell
dotnet ef database update 20260723182424_AddDiscoverMealPlanning --project src/NutritionTracker.Infrastructure --startup-project src/NutritionTracker.Api
```

The migration was applied to the local development database on 2026-07-24. Production deployment must apply the same migration through its normal release process.

## Publishing API and database changes

The repository does not assume a particular hosting provider. Publish the API and apply its EF migrations from the same release job (or directly on the server) that can reach the production PostgreSQL instance. Do not run the command below from a developer machine unless its connection string is intentionally pointed at production.

1. Build and publish the API from the commit being released:

```powershell
dotnet publish src/NutritionTracker.Api/NutritionTracker.Api.csproj -c Release -o .artifacts/api
```

2. Back up PostgreSQL and the configured retained-image storage before changing the server. Keep `ConnectionStrings__DefaultConnection`, JWT signing keys, provider credentials, and storage credentials in the host's secret store/environment; never copy them into the repository or publish folder.

3. Copy `.artifacts/api` (or the container image produced by the host's pipeline) to the server, then apply the migration using the server's production environment:

```powershell
$env:ASPNETCORE_ENVIRONMENT = "Production"
dotnet ef database update 20260723182424_AddDiscoverMealPlanning `
  --project src/NutritionTracker.Infrastructure `
  --startup-project src/NutritionTracker.Api
```

If the server only receives published binaries, run the same command from a release runner with the API project and migration assembly available, or add a one-shot migration job/container. EF records the migration in `__EFMigrationsHistory`, so rerunning it is safe and idempotent.

4. Restart the API service/container and verify `/health/ready`, authentication, and `GET /api/discover-meals/recommendations`. Confirm that `POST /api/discover-meals/plan/regenerate` returns 200 for a test account. The development header `X-Development-User-Id` is not accepted in Production; use a real JWT.

5. Because this release also contains Flutter changes, build and distribute a new mobile artifact through the normal signing channel. For local device verification use `./scripts/install-mobile.ps1`; production users need the signed Android/iOS release rather than the debug APK.

Keep the migration file in source control and deploy the API code and migration from the same commit. If a release is rolled back, do not delete migration history or manually drop these tables; deploy a forward migration after reviewing the schema change.

## Daily workflow

Use `./scripts/run-mobile.ps1`. For a USB-debugged Android device it uses ADB reverse first, so the app reaches the PC API through `127.0.0.1` without relying on Wi-Fi routing. It falls back to the detected LAN address only when ADB reverse is unavailable, starts the API if necessary, and starts Flutter with the correct development configuration. No ports or Dart defines need to be typed.

For a non-interactive installed debug APK, use `./scripts/install-mobile.ps1` instead of manually building and installing it. It resolves the same device/API route and embeds it as Flutter Dart defines before installation. A plain `flutter build apk --debug` uses the emulator-only fallback (`10.0.2.2`) and therefore cannot connect from a physical phone.

The Development API deliberately serves the mobile HTTP endpoint without an HTTPS redirect so Android can use ADB reverse or LAN HTTP. HTTPS remains required outside Development; Swagger remains available locally at `https://localhost:7241/swagger`.

For an emulator it automatically uses `10.0.2.2`. Set `NUTRILENS_API_BASE_URL` in `.env.local` only when automatic discovery is unsuitable.

## Phase 13 habits and reminders

Open **Progress -> Habits & routines** to log hydration, record a completed fasting window, and schedule a daily meal reminder. Habit records are stored in PostgreSQL for the current development identity. Reminder preferences are also persisted by the API, while delivery is scheduled locally by Android/iOS and therefore requires notification permission on that device.

The Progress screen can switch between weekly and monthly summaries. Only confirmed meals contribute to calories, meal counts, and adherence. Weight and nutrition trends are informational and are not medical guidance.

## Meal-image privacy and UI previews

Development meal images remain under the configured `MealAnalysis:LocalStorageRoot`. Mobile review/history screens retrieve them through the user-scoped `/api/meals/{mealId}/image` endpoint; filesystem storage keys are never returned. The mobile cache is memory-only and bounded. Set `MealAnalysis:RetainImages=false` when image review after upload is not required; image requests then return `404`.

The floating glass navigation and showcase transitions honor the device's reduced-motion setting. Test narrow layouts with `flutter test test/habits_responsive_test.dart` before changing global button sizing or habit-card actions.

## History activity calendar

History includes a trailing 12-month, Monday-aligned activity grid. **Meals** visualizes confirmed-meal frequency; **Target** visualizes closeness to the calorie target effective on each date. Selecting a square fetches only that profile-timezone day and filters the image-led meal list.

The supporting endpoint is `GET /api/meals/activity?fromDate=YYYY-MM-DD&toDate=YYYY-MM-DD`. It requires `X-Development-User-Id`, accepts at most 371 inclusive dates, excludes draft/failed/deleted meals, and returns each day's UTC boundaries for correct filtering. No migration is required because the response is derived from existing meals, profiles, and nutrition targets.

Visual regression baselines for the light/dark glass dock and activity grid are under `mobile/nutrition_tracker_app/test/goldens`. Update them only after intentionally reviewing a design change:

```powershell
cd mobile/nutrition_tracker_app
flutter test test/reference_ui_golden_test.dart --update-goldens
```

## Troubleshooting

- Confirm the PostgreSQL Windows service is running: `Get-Service postgresql*`.
- Confirm API/database readiness: `http://localhost:5241/health/ready`.
- If a phone cannot reach the API, confirm it is on the same Wi-Fi, allow TCP 5241 through Windows Firewall, and rerun `./scripts/run-mobile.ps1`.
- If an APK installed by a tool cannot reach the API but `run-mobile.ps1` can, reinstall it with `./scripts/install-mobile.ps1`. Flutter Dart defines are compiled into the APK; an APK built without that script falls back to the emulator address and will not work on a physical phone.
- An OpenAI configuration error means the API key or `MealVision:Provider=OpenAi` is missing from user secrets.
- A meal upload returning 503 usually means the local MCP service or Ollama is unavailable. Check `http://127.0.0.1:5250/health`, the MCP process output, and `ollama list`.
- A meal upload returning 422 means the image failed food-relevance or quality preflight. Use a clear, well-lit meal photo; the API does not retain rejected images.
- Set `NUTRILENS_ENABLE_MOCK_MODE=true` only when you intentionally need deterministic test scenarios. The startup script otherwise selects OpenAI and fails clearly if its key is absent. Mock output does not inspect image contents.
