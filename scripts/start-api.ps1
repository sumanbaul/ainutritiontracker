[CmdletBinding()]
param([switch]$ApplyMigrations)

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'DevelopmentEnvironment.ps1')
Import-NutriLensLocalEnvironment -RepositoryRoot $root

if ($ApplyMigrations) {
    & dotnet tool restore
    & dotnet tool run dotnet-ef database update --project (Join-Path $root 'src/NutritionTracker.Infrastructure') --startup-project (Join-Path $root 'src/NutritionTracker.Api')
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$env:ASPNETCORE_ENVIRONMENT = 'Development'
$env:ASPNETCORE_URLS = "http://0.0.0.0:$env:NUTRILENS_API_HTTP_PORT;https://localhost:7241"
if ($env:NUTRILENS_ENABLE_MOCK_MODE -eq 'true') {
    $env:MealVision__Provider = 'Mock'
    Write-Host 'Starting with deterministic mock meal vision.'
} else {
    $env:MealVision__Provider = 'OpenAi'
    Write-Host 'Starting with server-side OpenAI meal vision.'
}
& dotnet run --project (Join-Path $root 'src/NutritionTracker.Api') --no-launch-profile
