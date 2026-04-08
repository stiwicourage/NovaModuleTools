param(
    [string]$ModulePath = './dist/NovaModuleTools',
    [string]$ApiKey = $env:PSGALLERY_API
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    throw 'PSGALLERY_API environment variable is required.'
}

if (-not (Test-Path -LiteralPath $ModulePath)) {
    throw "Module path not found: $ModulePath"
}

Publish-PSResource -Path $ModulePath -Repository PSGallery -ApiKey $ApiKey -Verbose


