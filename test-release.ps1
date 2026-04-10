#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Write-Host "=== Building module ===" -ForegroundColor Cyan
Invoke-MTBuild
Write-Host "Build complete`n" -ForegroundColor Green

$projectName = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
$distModuleDir = Join-Path $PSScriptRoot "dist/$projectName"

Write-Host "=== Importing module ===" -ForegroundColor Cyan
Remove-Module $projectName -ErrorAction SilentlyContinue
Import-Module $distModuleDir -Force
Write-Host "Module imported`n" -ForegroundColor Green

Write-Host "=== Testing module ===" -ForegroundColor Cyan
Invoke-MTTest

Write-Host "`n=== Testing release pipeline ===" -ForegroundColor Cyan
Invoke-NovaRelease -PublishOption @{Local = $true}
Write-Host "`nRelease complete!" -ForegroundColor Green

