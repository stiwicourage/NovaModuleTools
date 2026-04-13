param(
    [string]$OutputDirectory = './artifacts',
    [string[]]$ExcludeTag = @()
)

Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'CodeSceneCoverageMap.ps1')
. (Join-Path $PSScriptRoot 'CodeSceneCoverageXml.ps1')
. (Join-Path $PSScriptRoot 'CoverageLowReport.ps1')

function Get-CiTestPath {
    param([Parameter(Mandatory)][pscustomobject]$ProjectInfo)

    if ($ProjectInfo.BuildRecursiveFolders) {
        return $ProjectInfo.TestsDir
    }

    return [System.IO.Path]::Join($ProjectInfo.TestsDir, '*.Tests.ps1')
}

function Get-CiPesterConfiguration {
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$ArtifactsDirectory,
        [string[]]$ExcludedTags = @()
    )

    $configuration = New-PesterConfiguration
    $configuration.Run.Path = Get-CiTestPath -ProjectInfo $ProjectInfo
    $configuration.Run.PassThru = $true
    $configuration.Filter.ExcludeTag = @($ExcludedTags)
    $configuration.TestResult.Enabled = $true
    $configuration.TestResult.OutputFormat = 'JUnitXml'
    $configuration.TestResult.OutputPath = (Join-Path $ArtifactsDirectory 'pester-junit.xml')
    $configuration.CodeCoverage.Enabled = $true
    $configuration.CodeCoverage.Path = @($ProjectInfo.ModuleFilePSM1)
    $configuration.CodeCoverage.OutputFormat = 'Cobertura'
    $configuration.CodeCoverage.OutputPath = (Join-Path $ArtifactsDirectory 'pester-coverage.cobertura.xml')

    return $configuration
}

function Copy-NovaModuleToolsTestResultIfPresent {
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$ArtifactsDirectory
    )

    $sourcePath = Join-Path $ProjectRoot 'artifacts/TestResults.xml'
    if (Test-Path -LiteralPath $sourcePath) {
        Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $ArtifactsDirectory 'novamoduletools-nunit.xml') -Force
    }
}

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..' '..' '..')).Path
Set-Location $repoRoot
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

Import-Module NovaModuleTools -ErrorAction Stop
Import-Module Pester -ErrorAction Stop

Invoke-NovaBuild

$projectInfo = Get-NovaProjectInfo
$builtModulePath = $projectInfo.OutputModuleDir
Remove-Module $projectInfo.ProjectName -ErrorAction SilentlyContinue
Import-Module $builtModulePath -Force
$projectInfo = Get-NovaProjectInfo

if (-not $projectInfo.SetSourcePath) {
    throw "Code coverage upload requires project.json to set SetSourcePath=true so dist line coverage can be remapped back to src/ files for CodeScene."
}

$novaModuleToolsTestFailed = $false
try {
    if (@($ExcludeTag).Count -gt 0) {
        Test-NovaBuild -ExcludeTagFilter $ExcludeTag
    }
    else {
        Test-NovaBuild
    }
}
catch {
    $novaModuleToolsTestFailed = $true
    Write-Warning "Test-NovaBuild failed: $( $_.Exception.Message )"
}
finally {
    Copy-NovaModuleToolsTestResultIfPresent -ProjectRoot $projectInfo.ProjectRoot -ArtifactsDirectory $OutputDirectory
}

$configuration = Get-CiPesterConfiguration -ProjectInfo $projectInfo -ArtifactsDirectory $OutputDirectory -ExcludedTags $ExcludeTag
$result = Invoke-Pester -Configuration $configuration
Convert-CoberturaCoverageToSourcePath -CoveragePath (Join-Path $OutputDirectory 'pester-coverage.cobertura.xml') -BuiltModulePath $projectInfo.ModuleFilePSM1 -RepoRoot $projectInfo.ProjectRoot
Write-CoverageLowReport -CoveragePath (Join-Path $OutputDirectory 'pester-coverage.cobertura.xml') -OutputPath (Join-Path $OutputDirectory 'coverage-low.txt')

if ($novaModuleToolsTestFailed -or $result.FailedCount -gt 0) {
    exit 1
}

