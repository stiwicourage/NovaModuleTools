function Test-ProjectSchema {param($Name) }
function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
function Get-NovaProjectInfo {}
function New-PesterConfiguration {param($Hashtable)}
function Get-NovaPesterRunPath {param($ProjectInfo) return 'tests' }
function Get-NovaPesterTestResultPath {param($ProjectRoot) return (Join-Path $ProjectRoot 'TestResults.xml')}
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
    param([Parameter(Mandatory)][object]$PesterSettings)
    [pscustomobject]@{
        Pester = $PesterSettings
        BuildRecursiveFolders = $false
        TestsDir = 'tests'
        ProjectRoot = '/tmp/nova-project'
        ModuleFilePSM1 = '/tmp/nova-project/dist/TestProject/TestProject.psm1'
    }
}
