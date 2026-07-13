param([string]$ApiUrl = 'http://localhost:5241', [string]$ImagePath, [string]$DevelopmentUserId = 'provider-smoke-user', [switch]$InvokePaidAnalysis)
$ErrorActionPreference = 'Stop'
Invoke-RestMethod "$ApiUrl/api/meal-vision/status" -Headers @{ 'X-Development-User-Id' = $DevelopmentUserId }
if (-not $InvokePaidAnalysis) { Write-Host 'Configuration verified. Pass -InvokePaidAnalysis -ImagePath <file> to make an opt-in provider call.'; exit 0 }
if (-not (Test-Path -LiteralPath $ImagePath)) { throw 'A valid ImagePath is required.' }
Invoke-RestMethod "$ApiUrl/api/meals/analyse" -Method Post -Headers @{ 'X-Development-User-Id' = $DevelopmentUserId } -Form @{ image = Get-Item -LiteralPath $ImagePath; consumedAtUtc = [DateTime]::UtcNow.ToString('o'); locale = 'en-IN' }
