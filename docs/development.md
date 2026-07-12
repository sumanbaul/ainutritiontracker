# Local development

## First-time setup

Run `./scripts/initialize-development.ps1` from PowerShell. It creates the ignored `.env.local` file and can store the OpenAI key in .NET user secrets. Secrets are never written to `.env.local`.

The API requires these user-secret values for real image analysis:

```powershell
dotnet user-secrets set "MealVision:Provider" "OpenAi" --project src/NutritionTracker.Api
dotnet user-secrets set "MealVision:OpenAi:ApiKey" "<your-key>" --project src/NutritionTracker.Api
```

Set `ConnectionStrings:DefaultConnection` in the same secret store for local PostgreSQL. Apply database migrations with `./scripts/start-api.ps1 -ApplyMigrations`.

## Daily workflow

Use `./scripts/run-mobile.ps1`. It finds the first authorized Android device, detects the computer LAN address for a physical device, starts the API if necessary, and starts Flutter with the correct development configuration. No ports or Dart defines need to be typed.

For an emulator it automatically uses `10.0.2.2`. Set `NUTRILENS_API_BASE_URL` in `.env.local` only when automatic discovery is unsuitable.

## Troubleshooting

- Confirm the PostgreSQL Windows service is running: `Get-Service postgresql*`.
- Confirm API/database readiness: `http://localhost:5241/health/ready`.
- If a phone cannot reach the API, confirm it is on the same Wi-Fi, allow TCP 5241 through Windows Firewall, and rerun `./scripts/run-mobile.ps1`.
- An OpenAI configuration error means the API key or `MealVision:Provider=OpenAi` is missing from user secrets.
- Set `NUTRILENS_ENABLE_MOCK_MODE=true` only when you intentionally need deterministic test scenarios. Mock output does not inspect image contents.
