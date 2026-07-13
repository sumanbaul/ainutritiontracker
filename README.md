# AI Nutrition Tracker

The Android-first Flutter client is under `mobile/nutrition_tracker_app`. It supports authenticated nutrition tracking, manual/recipe meals, camera analysis, habits, progress, and private meal images. See [local development](docs/development.md), [Phase 14](docs/phase-14.md), [Phase 15 integrity and self-hosting](docs/phase-15.md), [architecture](docs/architecture.md), [roadmap](docs/roadmap.md), and [status](docs/status.md).

Backend foundation for a mobile-first nutrition tracker that estimates meal nutrition from photographs and requires user review before logging. Phases 2–7 provide the backend foundation, profile targets, food data, mock vision, draft analysis, confirmation, and dashboard APIs; Flutter and production AI are deferred.

## Architecture

```text
src/
  NutritionTracker.Api/            HTTP pipeline, Swagger, health checks, exception handling
  NutritionTracker.Application/    Future use-case contracts and application services
  NutritionTracker.Domain/         Framework-independent domain abstractions
  NutritionTracker.Infrastructure/ EF Core, PostgreSQL, persistence configuration
tests/
  NutritionTracker.UnitTests/
  NutritionTracker.IntegrationTests/
```

The dependency direction is `Api -> Application + Infrastructure`, `Infrastructure -> Application + Domain`, and `Application -> Domain`.

## Requirements

- .NET SDK 10.0.301 (pinned in `global.json`)
- PostgreSQL 17 or Docker Compose

Docker is not installed on this workstation at the time this foundation was created. Install Docker Desktop or provide a reachable PostgreSQL instance before running database readiness checks or applying migrations.

## Local setup

1. Run `./scripts/initialize-development.ps1`. It creates `.env.local` with safe defaults and keeps secrets in .NET user secrets.
2. Start PostgreSQL:

   ```powershell
   docker compose up -d postgres
   ```

3. Set the API connection string using .NET user secrets:

   ```powershell
   dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Host=localhost;Port=5432;Database=nutrition_tracker;Username=nutrition_tracker;Password=YOUR_LOCAL_PASSWORD" --project src/NutritionTracker.Api
   ```

4. Restore, migrate, and run:

   ```powershell
   dotnet restore
   dotnet ef database update --project src/NutritionTracker.Infrastructure --startup-project src/NutritionTracker.Api
   ./scripts/start-api.ps1 -ApplyMigrations
   ```

Swagger is available in Development at `https://localhost:7241/swagger`. Liveness is `GET /health`; database readiness is `GET /health/ready`.

## Tests

```powershell
dotnet format --verify-no-changes
dotnet build NutritionTracker.sln --no-restore
dotnet test NutritionTracker.sln --no-build
```

The health-only test runs without PostgreSQL. Persistence integration tests run only when `NUTRITION_TRACKER_INTEGRATION_CONNECTION` is configured to the dedicated PostgreSQL test database.

## Configuration and secrets

`appsettings.json` deliberately contains no connection string or provider secret. Use user secrets locally, environment variables in deployed environments, and a managed secret store in production. Do not commit `.env`, user secrets, credentials, JWT signing keys, or AI provider keys.

## Current limitations

- Development may use `X-Development-User-Id`; production uses rotating JWT sessions and rejects the development identity path.
- Protected local image storage is supported for explicitly enabled self-hosted production deployments; S3-compatible private storage remains optional and operator supplied.
- OpenAI image analysis requires a server-side API key; nutrition remains sourced from the food database after user review.

## Phase 5 mock meal vision

Development and Testing expose `POST /api/development/meal-vision/analyse`. It requires `X-Development-User-Id` and a small base64 JPEG, PNG, or WebP payload. `MealVision:Provider` defaults to `Mock`; production refuses Mock unless explicitly opted in. The mock never transmits or persists images and never returns final nutrition values. See `docs/meal-vision-architecture.md` and `docs/meal-vision-prompts.md`.

## Phase 6 draft meal analysis

`POST /api/meals/analyse` accepts a validated multipart `image` and creates an `AwaitingReview` draft using mock vision, food-database matching, and per-100-gram scaling. `GET /api/meals/{mealId}/review` is user-isolated. Drafts are not confirmed and do not update daily totals. See `docs/meal-analysis-pipeline.md`.

## Phase 7 meal confirmation and dashboard

Draft items can be corrected, added, or removed before `POST /api/meals/{mealId}/confirm`. `GET /api/meals` returns confirmed history and `GET /api/dashboard/today` returns the daily confirmed totals. Deleting an owned meal recalculates its daily summary. Correction records are retained for audit. See `docs/meal-confirmation-and-dashboard.md`.

## Phase 3 profile API

Temporary development requests require `X-Development-User-Id`; this will be replaced by authentication. `POST/GET/PUT /api/profile`, `POST /api/profile/recalculate-targets`, and `POST/GET /api/weight` are available. See `docs/nutrition-calculation.md`; targets are estimates and not medical advice.

### Windows PostgreSQL

Confirm the `postgresql-x64-18` service is running with `Get-Service postgresql-x64-18`. On this machine `psql` is at `X:\Program Files\PostgreSQL\18\bin\psql.exe`; add that folder to `PATH` if desired. Store `ConnectionStrings:DefaultConnection` using `dotnet user-secrets set`, create the development database with `psql -U postgres -c "CREATE DATABASE nutrition_tracker_dev;"`, then run `dotnet tool run dotnet-ef database update --project src/NutritionTracker.Infrastructure --startup-project src/NutritionTracker.Api`. Verify database connectivity at `https://localhost:7241/health/ready`.

PostgreSQL integration tests use only `nutrition_tracker_integration_tests` through the `NUTRITION_TRACKER_INTEGRATION_CONNECTION` environment variable. Never point it at `nutrition_tracker_dev` or production.
