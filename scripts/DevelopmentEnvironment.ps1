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
