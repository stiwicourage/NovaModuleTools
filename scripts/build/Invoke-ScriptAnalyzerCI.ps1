param(
    [string]$OutputDirectory = './artifacts'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$sharedCiRoot = if ($env:POWERSHELL_CI_PATH) { $env:POWERSHELL_CI_PATH } else { Join-Path $repositoryRoot '../powershell-ci' }
$sharedScript = Join-Path $sharedCiRoot 'actions/script-analyzer/Invoke-ScriptAnalyzerCI.ps1'
if (-not (Test-Path -LiteralPath $sharedScript -PathType Leaf)) {
    throw "The shared powershell-ci checkout was not found at '$sharedCiRoot'. Clone stiwicourage/powershell-ci next to this repository or set POWERSHELL_CI_PATH."
}

& $sharedScript -ProjectRoot $repositoryRoot -OutputDirectory $OutputDirectory -RequiredVersion '1.25.0' `
    -AnalysisPath 'src', 'scripts', 'run.ps1' -Severity 'Error', 'Warning', 'ParseError'
if ($LASTEXITCODE -ne 0) {
    throw "PSScriptAnalyzer gate failed with exit code $LASTEXITCODE."
}
