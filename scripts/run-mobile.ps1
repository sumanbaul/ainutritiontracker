[CmdletBinding()]
param()

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'DevelopmentEnvironment.ps1')
Import-NutriLensLocalEnvironment -RepositoryRoot $root

$device = Get-NutriLensMobileDevice
$env:NUTRILENS_API_BASE_URL = Resolve-NutriLensMobileApiBaseUrl -Device $device

try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 "$env:NUTRILENS_API_BASE_URL/health" | Out-Null }
catch {
    Start-Process powershell -ArgumentList @('-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'start-api.ps1')) | Out-Null
    $deadline = (Get-Date).AddSeconds(30)
    do {
        Start-Sleep -Seconds 1
        try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 "$env:NUTRILENS_API_BASE_URL/health" | Out-Null; break } catch { }
    } while ((Get-Date) -lt $deadline)
}

Set-Location (Join-Path $root 'mobile/nutrition_tracker_app')
& flutter run -d $device --dart-define=APP_ENV=development --dart-define=API_BASE_URL=$env:NUTRILENS_API_BASE_URL --dart-define=DEVELOPMENT_USER_ID=$env:NUTRILENS_DEVELOPMENT_USER_ID --dart-define=ENABLE_MOCK_MODE=$env:NUTRILENS_ENABLE_MOCK_MODE
