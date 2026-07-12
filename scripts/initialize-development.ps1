[CmdletBinding()]
param()

$root = Split-Path -Parent $PSScriptRoot
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) { throw 'The .NET SDK is required.' }
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { Write-Warning 'Flutter was not found. Backend setup can continue.' }

if (-not (Test-Path (Join-Path $root '.env.local'))) {
    Copy-Item (Join-Path $root '.env.example') (Join-Path $root '.env.local')
    Write-Host 'Created .env.local from .env.example. It contains no secrets.'
}

& dotnet user-secrets init --project (Join-Path $root 'src/NutritionTracker.Api')
Write-Host ''
Write-Host 'Set your existing PostgreSQL connection string once, if not already configured:'
Write-Host 'dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Host=localhost;Port=5432;Database=nutrition_tracker_dev;Username=postgres;Password=<password>" --project src/NutritionTracker.Api'
Write-Host ''
$configure = Read-Host 'Configure the OpenAI API key now? (y/N)'
if ($configure -match '^(y|yes)$') {
    $key = Read-Host 'OpenAI API key' -AsSecureString
    $plain = [System.Net.NetworkCredential]::new('', $key).Password
    try {
        & dotnet user-secrets set 'MealVision:Provider' 'OpenAi' --project (Join-Path $root 'src/NutritionTracker.Api')
        & dotnet user-secrets set 'MealVision:OpenAi:ApiKey' $plain --project (Join-Path $root 'src/NutritionTracker.Api')
        Write-Host 'OpenAI configuration was saved to the local user-secret store.'
    } finally {
        $plain = $null
    }
}
