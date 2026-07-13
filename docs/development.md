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

The Bengali/Kolkata catalog is seeded at Development startup. It contains curated, medium-confidence recipe estimates and aliases, not reproduced IFCT data. Review every AI estimate; vendor oil, sugar, portions, and recipes can materially change nutrition.

## Daily workflow

Use `./scripts/run-mobile.ps1`. For a USB-debugged Android device it uses ADB reverse first, so the app reaches the PC API through `127.0.0.1` without relying on Wi-Fi routing. It falls back to the detected LAN address only when ADB reverse is unavailable, starts the API if necessary, and starts Flutter with the correct development configuration. No ports or Dart defines need to be typed.

The Development API deliberately serves the mobile HTTP endpoint without an HTTPS redirect so Android can use ADB reverse or LAN HTTP. HTTPS remains required outside Development; Swagger remains available locally at `https://localhost:7241/swagger`.

For an emulator it automatically uses `10.0.2.2`. Set `NUTRILENS_API_BASE_URL` in `.env.local` only when automatic discovery is unsuitable.

## Troubleshooting

- Confirm the PostgreSQL Windows service is running: `Get-Service postgresql*`.
- Confirm API/database readiness: `http://localhost:5241/health/ready`.
- If a phone cannot reach the API, confirm it is on the same Wi-Fi, allow TCP 5241 through Windows Firewall, and rerun `./scripts/run-mobile.ps1`.
- An OpenAI configuration error means the API key or `MealVision:Provider=OpenAi` is missing from user secrets.
- Set `NUTRILENS_ENABLE_MOCK_MODE=true` only when you intentionally need deterministic test scenarios. The startup script otherwise selects OpenAI and fails clearly if its key is absent. Mock output does not inspect image contents.
