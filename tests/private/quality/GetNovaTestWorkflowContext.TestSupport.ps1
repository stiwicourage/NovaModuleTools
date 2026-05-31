function Test-ProjectSchema {param($Name) }
function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
function Get-NovaProjectInfo {}
function New-PesterConfiguration {param($Hashtable)}
function Get-NovaPesterRunPath {
    param($ProjectInfo, $IncludePattern, $ExcludePattern)

    $script:lastRunPathRequest = [pscustomobject]@{
        ProjectInfo = $ProjectInfo
        IncludePattern = $IncludePattern
        ExcludePattern = $ExcludePattern
    }

    return @('tests/Example.Tests.ps1')
}
function Get-NovaPesterTestResultPath {
    param($ProjectRoot, $FileName)

    $script:lastResultPathRequest = [pscustomobject]@{
        ProjectRoot = $ProjectRoot
        FileName = $FileName
    }

    return (Join-Path $ProjectRoot $FileName)
}
function Initialize-NovaPesterExecutionConfiguration {param($PesterConfig, $BoundParameters, $OutputVerbosity, $OutputRenderMode)}
function Get-NovaShouldProcessForwardingParameter {param([switch]$WhatIfEnabled) return @{}}
function Write-NovaPesterTestResultArtifact {}
function Write-NovaPesterTestResultReport {}

$script:getPesterConfig = {
    [pscustomobject]@{
        Run = [pscustomobject]@{Path = $null; PassThru = $false; Exit = $false; Throw = $false}
        Filter = [pscustomobject]@{Tag = @(); ExcludeTag = @()}
        Output = [pscustomobject]@{Verbosity = 'Detailed'; RenderMode = 'Auto'}
        TestResult = [pscustomobject]@{Enabled = $true; OutputPath = $null}
        CodeCoverage = [pscustomobject]@{Enabled = $true; CoveragePercentTarget = 80; Path = $null}
    }
}

$script:getProjectInfo = {
    param(
        [Parameter(Mandatory)][object]$PesterSettings,
        [string]$ProjectRoot = (Join-Path $TestDrive 'nova-project')
    )

    [pscustomobject]@{
        Pester = $PesterSettings
        BuildRecursiveFolders = $true
        TestsDir = (Join-Path $ProjectRoot 'tests')
        ProjectRoot = $ProjectRoot
        ProjectName = 'NovaProject'
        ModuleFilePSM1 = (Join-Path $ProjectRoot 'dist/TestProject/TestProject.psm1')
    }
}
