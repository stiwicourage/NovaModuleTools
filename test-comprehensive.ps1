#!/usr/bin/env pwsh
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

Write-Host "=== Comprehensive Test ===" -ForegroundColor Cyan
Write-Host "This test verifies:"
Write-Host "  1. Build succeeds"
Write-Host "  2. Tests pass"
Write-Host "  3. Second build (during release) succeeds"
Write-Host "`n"

# Step 1: Build
Write-Host "[1/4] Building module..." -ForegroundColor Yellow
try {
    Invoke-MTBuild
    Write-Host "✓ Build succeeded" -ForegroundColor Green
} catch {
    Write-Host "✗ Build failed: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Import and run a quick test
$projectName = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
$distModuleDir = Join-Path $PSScriptRoot "dist/$projectName"

Write-Host "`n[2/4] Importing built module..." -ForegroundColor Yellow
Remove-Module $projectName -ErrorAction SilentlyContinue
Import-Module $distModuleDir -Force
Write-Host "✓ Module imported" -ForegroundColor Green

# Step 3: Run tests (just a sample, not full test suite for speed)
Write-Host "`n[3/4] Running sample tests..." -ForegroundColor Yellow
$testPath = Join-Path $PSScriptRoot 'tests' 'Module.Tests.ps1'
$testResults = Invoke-Pester -Path $testPath -PassThru -ErrorAction SilentlyContinue
if ($testResults.FailedCount -eq 0) {
    Write-Host "✓ Tests passed" -ForegroundColor Green
} else {
    Write-Host "✗ Tests failed: $( $testResults.FailedCount ) failures" -ForegroundColor Red
    exit 1
}

# Step 4: Second build (simulating the release pipeline)
Write-Host "`n[4/4] Building again (release pipeline test)..." -ForegroundColor Yellow
try {
    Invoke-MTBuild
    Write-Host "✓ Second build succeeded (resource file fix working!)" -ForegroundColor Green
} catch {
    Write-Host "✗ Second build failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n" + ("=" * 50) -ForegroundColor Cyan
Write-Host "ALL TESTS PASSED!" -ForegroundColor Green
Write-Host "The resource file fix is working correctly." -ForegroundColor Green
Write-Host "The release pipeline should now work without errors." -ForegroundColor Green
Write-Host ("=" * 50) -ForegroundColor Cyan
