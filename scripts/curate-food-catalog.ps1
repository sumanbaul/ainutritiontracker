[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [ValidateSet('validate', 'preview', 'publish', 'deprecate')] [string] $Action,
    [Parameter(Mandatory)] [string] $ManifestPath,
    [switch] $Production
)

$ErrorActionPreference = 'Stop'
if ($Production -and $env:ALLOW_NUTRILENS_PRODUCTION_CURATION -ne 'true') {
    throw 'Production curation is disabled. Set ALLOW_NUTRILENS_PRODUCTION_CURATION=true only in an approved server session.'
}
if (-not (Test-Path -LiteralPath $ManifestPath)) { throw "Manifest not found: $ManifestPath" }
$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
foreach ($required in 'version','source','reference','foods') { if ($null -eq $manifest.$required) { throw "Manifest is missing '$required'." } }
if ([string]::IsNullOrWhiteSpace($manifest.source) -or [string]::IsNullOrWhiteSpace($manifest.reference)) { throw 'Source and reference are required for every curated catalog import.' }
if ($Action -eq 'publish' -and -not $manifest.approved) { throw 'Publishing requires approved=true in the reviewed manifest.' }
Write-Host "Curation $Action validated for catalog version $($manifest.version)."
Write-Host 'This server-only guard does not import third-party data automatically; add a reviewed, licence-compatible importer before publishing records.'
