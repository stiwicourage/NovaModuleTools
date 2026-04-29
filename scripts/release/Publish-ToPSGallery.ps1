param(
    [string]$ModulePath = './dist/NovaModuleTools',
    [string]$ApiKey = $env:PSGALLERY_API
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptRoot 'SemanticReleaseSupport.ps1')

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    throw 'PSGALLERY_API environment variable is required.'
}

if (-not (Test-Path -LiteralPath $ModulePath)) {
    throw "Module path not found: $ModulePath"
}

Initialize-PSGalleryRepository
Publish-PSResource -Path $ModulePath -Repository PSGallery -ApiKey $ApiKey -Verbose -ErrorAction Stop
