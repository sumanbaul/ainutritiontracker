[CmdletBinding()]
param()

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'DevelopmentEnvironment.ps1')
Import-NutriLensLocalEnvironment -RepositoryRoot $root

$device = Get-NutriLensMobileDevice
$apiBaseUrl = Resolve-NutriLensMobileApiBaseUrl -Device $device

try {
    Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 "$apiBaseUrl/health" | Out-Null
} catch {
    Start-Process powershell -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $PSScriptRoot 'start-api.ps1')) -WorkingDirectory $root -WindowStyle Hidden | Out-Null
    $deadline = (Get-Date).AddSeconds(30)
    do {
        Start-Sleep -Seconds 1
        try {
            Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 "$apiBaseUrl/health" | Out-Null
            break
        } catch { }
    } while ((Get-Date) -lt $deadline)
}

Set-Location (Join-Path $root 'mobile/nutrition_tracker_app')
& flutter build apk --debug "--dart-define=APP_ENV=development" "--dart-define=API_BASE_URL=$apiBaseUrl" "--dart-define=DEVELOPMENT_USER_ID=$env:NUTRILENS_DEVELOPMENT_USER_ID" "--dart-define=ENABLE_MOCK_MODE=$env:NUTRILENS_ENABLE_MOCK_MODE"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$apk = Join-Path (Get-Location) 'build/app/outputs/flutter-apk/app-debug.apk'
& adb -s $device install -r $apk
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& adb -s $device shell monkey -p com.suman.nutrilens 1 | Out-Null
Write-Host "Installed NutriLens on $device using $apiBaseUrl."
