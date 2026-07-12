[CmdletBinding()]
param()

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'DevelopmentEnvironment.ps1')
Import-NutriLensLocalEnvironment -RepositoryRoot $root

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) { throw 'Android platform-tools (adb) are required.' }
$devices = (& adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\sdevice$' } | ForEach-Object { ($_ -split '\s+')[0] })
if ($devices.Count -eq 0) { throw 'No authorized Android device or emulator is connected.' }
$device = if ($env:NUTRILENS_MOBILE_DEVICE -ne 'auto') { $env:NUTRILENS_MOBILE_DEVICE } else { $devices[0] }

if ([string]::IsNullOrWhiteSpace($env:NUTRILENS_API_BASE_URL)) {
    if ($device -like 'emulator-*' -or $env:NUTRILENS_MOBILE_DEVICE -eq 'emulator') {
        $env:NUTRILENS_API_BASE_URL = "http://10.0.2.2:$env:NUTRILENS_API_HTTP_PORT"
    } else {
        $lanAddress = Get-NutriLensLanAddress
        if ([string]::IsNullOrWhiteSpace($lanAddress)) { throw 'No LAN IPv4 address was found. Set NUTRILENS_API_BASE_URL in .env.local.' }
        $env:NUTRILENS_API_BASE_URL = "http://${lanAddress}:$env:NUTRILENS_API_HTTP_PORT"
    }
}

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
