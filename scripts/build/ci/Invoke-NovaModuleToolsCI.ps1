param(
    [string]$OutputDirectory = './artifacts',
    [string[]]$ExcludeTag = @()
)

Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'CodeSceneCoverageMap.ps1')
. (Join-Path $PSScriptRoot 'CodeSceneCoverageXml.ps1')
. (Join-Path $PSScriptRoot 'CoverageLowReport.ps1')

function Get-CiTestWorkflowContext {
    param(
        [Parameter(Mandatory)][string]$ProjectName,
        [string[]]$ExcludedTags = @()
    )

    $module = Get-Module -Name $ProjectName -ErrorAction Stop
    $testOption = @{}
    if (@($ExcludedTags).Count -gt 0) {
        $testOption.ExcludeTagFilter = @($ExcludedTags)
    }

    return & $module {
        param($ContextTestOption)

        Get-NovaTestWorkflowContext -TestOption $ContextTestOption -BoundParameters @{}
    } $testOption
}

function Get-CiPesterConfiguration {
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [Parameter(Mandatory)][string]$ArtifactsDirectory,
        [string[]]$ExcludedTags = @()
    )

    $configuration = $WorkflowContext.PesterConfig
    $configuration.Run.PassThru = $true
    $configuration.Run.Exit = $false
    $configuration.Run.Throw = $false
    $configuration.Filter.ExcludeTag = @($ExcludedTags)
    $configuration.TestResult.Enabled = $true
    $configuration.TestResult.OutputFormat = 'JUnitXml'
    $configuration.TestResult.OutputPath = (Join-Path $ArtifactsDirectory 'pester-junit.xml')
    $configuration.CodeCoverage.Enabled = $true
    $configuration.CodeCoverage.Path = @($WorkflowContext.ProjectInfo.ModuleFilePSM1)
    $configuration.CodeCoverage.OutputFormat = 'Cobertura'
    $configuration.CodeCoverage.OutputPath = (Join-Path $ArtifactsDirectory 'pester-coverage.cobertura.xml')

    return $configuration
}

function Write-CiNovaModuleToolsTestResult {
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [Parameter(Mandatory)][string]$ArtifactsDirectory,
        [Parameter(Mandatory)][object]$TestResult
    )

    & $WorkflowContext.TestResultReportWriter.ScriptBlock -TestResult $TestResult -OutputPath (Join-Path $ArtifactsDirectory 'novamoduletools-nunit.xml')
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

$workflowContext = Get-CiTestWorkflowContext -ProjectName $projectInfo.ProjectName -ExcludedTags $ExcludeTag
$configuration = Get-CiPesterConfiguration -WorkflowContext $workflowContext -ArtifactsDirectory $OutputDirectory -ExcludedTags $ExcludeTag
$result = Invoke-Pester -Configuration $configuration
Write-CiNovaModuleToolsTestResult -WorkflowContext $workflowContext -ArtifactsDirectory $OutputDirectory -TestResult $result
Convert-CoberturaCoverageToSourcePath -CoveragePath (Join-Path $OutputDirectory 'pester-coverage.cobertura.xml') -BuiltModulePath $projectInfo.ModuleFilePSM1 -RepoRoot $projectInfo.ProjectRoot
Write-CoverageLowReport -CoveragePath (Join-Path $OutputDirectory 'pester-coverage.cobertura.xml') -OutputPath (Join-Path $OutputDirectory 'coverage-low.txt')

if ($result.FailedCount -gt 0) {
    exit 1
}
