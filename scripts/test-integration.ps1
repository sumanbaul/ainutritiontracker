param([string]$ConnectionString = $env:NUTRITION_TRACKER_INTEGRATION_CONNECTION)
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ConnectionString) -or $ConnectionString -notmatch '(?i)(test|integration)') { throw 'Use a dedicated database whose connection string contains test or integration.' }
$env:NUTRITION_TRACKER_INTEGRATION_CONNECTION = $ConnectionString
dotnet tool restore
dotnet tool run dotnet-ef database update --project src/NutritionTracker.Infrastructure --startup-project src/NutritionTracker.Api
dotnet test tests/NutritionTracker.IntegrationTests/NutritionTracker.IntegrationTests.csproj
