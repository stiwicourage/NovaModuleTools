Set-Location $PSScriptRoot
& "$PSScriptRoot/nova" build
if (Test-Path -LiteralPath "$PSScriptRoot/dist/NovaModuleTools/NovaModuleTools.psm1") {
    Write-Host 'VERIFY_OK'
} else {
    Write-Host 'VERIFY_MISSING_OUTPUT'
}

