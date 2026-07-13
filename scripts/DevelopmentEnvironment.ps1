function Import-NutriLensLocalEnvironment {
    param([string]$RepositoryRoot)

    $defaults = @{
        NUTRILENS_API_HTTP_PORT = '5241'
        NUTRILENS_DEVELOPMENT_USER_ID = 'local-mobile-user'
        NUTRILENS_ENABLE_MOCK_MODE = 'false'
        NUTRILENS_MOBILE_DEVICE = 'auto'
    }
    foreach ($entry in $defaults.GetEnumerator()) {
        if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($entry.Key))) {
            Set-Item -Path "Env:$($entry.Key)" -Value $entry.Value
        }
    }

    $localFile = Join-Path $RepositoryRoot '.env.local'
    if (-not (Test-Path -LiteralPath $localFile)) { return }
    foreach ($line in Get-Content -LiteralPath $localFile) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith('#') -or $trimmed -notmatch '=') { continue }
        $name, $value = $trimmed.Split('=', 2)
        $name = $name.Trim()
        if ($name.Length -gt 0) { Set-Item -Path "Env:$name" -Value $value.Trim().Trim('"').Trim("'") }
    }
}

function Get-NutriLensLanAddress {
    $route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
        Where-Object { $_.NextHop -ne '0.0.0.0' } |
        Sort-Object RouteMetric |
        Select-Object -First 1
    if ($null -eq $route) { return $null }
    return (Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $route.InterfaceIndex -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -notlike '127.*' } |
        Select-Object -First 1 -ExpandProperty IPAddress)
}

function Get-NutriLensMobileDevice {
    if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
        throw 'Android platform-tools (adb) are required.'
    }

    $devices = @(& adb devices | Select-Object -Skip 1 |
        Where-Object { $_ -match '\sdevice$' } |
        ForEach-Object { ($_ -split '\s+')[0] })
    if ($devices.Count -eq 0) {
        throw 'No authorized Android device or emulator is connected.'
    }

    if ($env:NUTRILENS_MOBILE_DEVICE -ne 'auto') {
        if ($devices -notcontains $env:NUTRILENS_MOBILE_DEVICE) {
            throw "Configured device '$env:NUTRILENS_MOBILE_DEVICE' is not connected."
        }
        return $env:NUTRILENS_MOBILE_DEVICE
    }

    return $devices[0]
}

function Resolve-NutriLensMobileApiBaseUrl {
    param([Parameter(Mandatory = $true)][string]$Device)

    if (-not [string]::IsNullOrWhiteSpace($env:NUTRILENS_API_BASE_URL)) {
        return $env:NUTRILENS_API_BASE_URL.TrimEnd('/')
    }

    if ($Device -like 'emulator-*' -or $env:NUTRILENS_MOBILE_DEVICE -eq 'emulator') {
        return "http://10.0.2.2:$env:NUTRILENS_API_HTTP_PORT"
    }

    & adb -s $Device reverse "tcp:$env:NUTRILENS_API_HTTP_PORT" "tcp:$env:NUTRILENS_API_HTTP_PORT" | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host 'Using USB ADB reverse for the API connection.'
        return "http://127.0.0.1:$env:NUTRILENS_API_HTTP_PORT"
    }

    $lanAddress = Get-NutriLensLanAddress
    if ([string]::IsNullOrWhiteSpace($lanAddress)) {
        throw 'No LAN IPv4 address was found. Set NUTRILENS_API_BASE_URL in .env.local.'
    }
    Write-Warning 'ADB reverse was unavailable; using the detected LAN address instead.'
    return "http://${lanAddress}:$env:NUTRILENS_API_HTTP_PORT"
}
