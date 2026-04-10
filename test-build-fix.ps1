#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Write-Host "=== Quick test: Building module ===" -ForegroundColor Cyan
try {
    Invoke-MTBuild
    Write-Host "✓ Build succeeded" -ForegroundColor Green
} catch {
    Write-Host "✗ Build failed: $_" -ForegroundColor Red
    exit 1
}

$projectName = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
$distModuleDir = Join-Path $PSScriptRoot "dist/$projectName"

Write-Host "`n=== Quick test: Build again (second build) ===" -ForegroundColor Cyan
Remove-Module $projectName -ErrorAction SilentlyContinue
Import-Module $distModuleDir -Force

try {
    Invoke-MTBuild
    Write-Host "✓ Second build succeeded" -ForegroundColor Green
} catch {
    Write-Host "✗ Second build failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== SUCCESS ===" -ForegroundColor Green
Write-Host "The resource file fix is working correctly!"
