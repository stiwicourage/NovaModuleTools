param(
    [string]$OutputDirectory = './artifacts',
    [switch]$IncludeTests
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Set-Location (Split-Path -Parent $PSScriptRoot | Split-Path -Parent)
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

Import-Module PSScriptAnalyzer -ErrorAction Stop

$settingsPath = @{
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'
    )
}

$analysisPaths = @(
    'src',
    'scripts',
    'run.ps1'
)

if ($IncludeTests) {
    $analysisPaths += 'tests'
}

$results = foreach ($analysisPath in $analysisPaths) {
    Invoke-ScriptAnalyzer -Path $analysisPath -Recurse -Settings $settingsPath |
            Where-Object {$_.Severity -in @('Error', 'Warning', 'ParseError')}
}

$results = @($results)

$reportPath = Join-Path $OutputDirectory 'scriptanalyzer.txt'
if ($results.Count -eq 0) {
    'PSScriptAnalyzer: no findings.' | Set-Content -LiteralPath $reportPath
    Write-Host 'PSScriptAnalyzer: no findings.'
    return
}

$report = $results |
        Sort-Object Severity, RuleName, ScriptName, Line |
        Select-Object Severity, RuleName, ScriptName, Line, Message |
        Format-Table -AutoSize |
        Out-String -Width 240

$report | Set-Content -LiteralPath $reportPath
Write-Host $report

$warningCount = @($results | Where-Object {$_.Severity -eq 'Warning'}).Count
$errorCount = @($results | Where-Object {$_.Severity -in @('Error', 'ParseError')}).Count
throw "PSScriptAnalyzer found $errorCount error(s) and $warningCount warning(s). See $reportPath for details."
