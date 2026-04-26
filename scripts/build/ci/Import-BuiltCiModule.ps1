param(
    [string]$RepositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..' '..' '..')).Path,
    [string]$ProjectName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ( [string]::IsNullOrWhiteSpace($ProjectName)) {
    $projectJsonPath = Join-Path $RepositoryRoot 'project.json'
    $ProjectName = (Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json).ProjectName
}

$moduleManifestPath = Join-Path $RepositoryRoot "dist/$ProjectName/$ProjectName.psd1"
if (-not (Test-Path -LiteralPath $moduleManifestPath)) {
    throw "Built module manifest not found: $moduleManifestPath"
}

Remove-Module -Name $ProjectName -Force -ErrorAction SilentlyContinue
return Import-Module -Name $moduleManifestPath -Force -PassThru -ErrorAction Stop
