$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Get-ChildItem -Path (Join-Path $PSScriptRoot 'src/private') -Filter '*.ps1' -File -Recurse |
        Sort-Object FullName |
        ForEach-Object {. $_.FullName}

Get-ChildItem -Path (Join-Path $PSScriptRoot 'src/public') -Filter '*.ps1' -File -Recurse |
        Sort-Object FullName |
        ForEach-Object {. $_.FullName}

Invoke-MTBuild
Write-Host 'VERIFY_SOURCE_BUILD_OK'

