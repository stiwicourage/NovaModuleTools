param(
    [string]$OutputDirectory = './artifacts',
    [switch]$IncludeTests
)

Set-StrictMode -Version Latest

Set-Location (Split-Path -Parent $PSScriptRoot | Split-Path -Parent)
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

function Test-IsGeneratedAnalysisPath {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$RepositoryRoot
    )

    $relativePath = [System.IO.Path]::GetRelativePath(
            [System.IO.Path]::GetFullPath($RepositoryRoot),
            [System.IO.Path]::GetFullPath($Path)
    ).Replace('\', '/')

    return $relativePath -match '(^|.*/)(dist|artifacts)(/|$)'
}

function Get-ScriptAnalyzerInputPathList {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$RepositoryRoot
    )

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return Get-ChildItem -LiteralPath $Path -Recurse -File |
            Where-Object {$_.Extension -in @('.ps1', '.psm1', '.psd1')} |
            Where-Object {-not (Test-IsGeneratedAnalysisPath -Path $_.FullName -RepositoryRoot $RepositoryRoot)} |
            ForEach-Object FullName
}

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

$repositoryRoot = (Get-Location).Path
$analysisFilePathList = @(foreach ($analysisPath in $analysisPaths) {
    Get-ScriptAnalyzerInputPathList -Path $analysisPath -RepositoryRoot $repositoryRoot
})

$results = foreach ($analysisFilePath in $analysisFilePathList) {
    Invoke-ScriptAnalyzer -Path $analysisFilePath -Settings $settingsPath |
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
