BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/GetNovaTestWorkflowContext.ps1')

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
}

Describe 'Get-NovaTestWorkflowContext' {
    BeforeEach {
        Mock Test-ProjectSchema {}
        Mock Get-Module {[pscustomobject]@{Name = 'Pester'}} -ParameterFilter {$Name -eq 'Pester' -and $ListAvailable}
        Mock Get-Command {[pscustomobject]@{ScriptBlock = {}}} -ParameterFilter {$CommandType -eq 'Function'}
    }

    It 'applies CoveragePercentTarget from project.json to the Pester configuration' {
        $pesterConfig = & $script:getPesterConfig
        $projectInfo = & $script:getProjectInfo -PesterSettings ([ordered]@{
            CodeCoverage = [ordered]@{Enabled = $true; CoveragePercentTarget = 99}
        })

        Mock Get-NovaProjectInfo {$projectInfo}
        Mock New-PesterConfiguration {$pesterConfig}

        $result = Get-NovaTestWorkflowContext -TestOption @{} -BoundParameters @{}

        $result.PesterConfig.CodeCoverage.CoveragePercentTarget | Should -Be 99
    }

    It 'keeps the default Pester coverage target when project.json omits CoveragePercentTarget' {
        $pesterConfig = & $script:getPesterConfig
        $projectInfo = & $script:getProjectInfo -PesterSettings ([ordered]@{
            CodeCoverage = [ordered]@{Enabled = $true}
        })

        Mock Get-NovaProjectInfo {$projectInfo}
        Mock New-PesterConfiguration {$pesterConfig}

        $result = Get-NovaTestWorkflowContext -TestOption @{} -BoundParameters @{}

        $result.PesterConfig.CodeCoverage.CoveragePercentTarget | Should -Be 80
    }

    It 'does not override CodeCoverage.Path when coverage is enabled (project.json owns Path)' {
        $pesterConfig = & $script:getPesterConfig
        $projectInfo = & $script:getProjectInfo -PesterSettings ([ordered]@{
            CodeCoverage = [ordered]@{Enabled = $true; CoveragePercentTarget = 90}
        })

        Mock Get-NovaProjectInfo {$projectInfo}
        Mock New-PesterConfiguration {$pesterConfig}

        $result = Get-NovaTestWorkflowContext -TestOption @{} -BoundParameters @{}

        $result.PesterConfig.CodeCoverage.Path | Should -BeNullOrEmpty
    }

    It 'does not set CodeCoverage.Path when coverage is disabled' {
        $pesterConfig = & $script:getPesterConfig
        $projectInfo = & $script:getProjectInfo -PesterSettings ([ordered]@{
            CodeCoverage = [ordered]@{Enabled = $false}
        })

        Mock Get-NovaProjectInfo {$projectInfo}
        Mock New-PesterConfiguration {$pesterConfig}

        $result = Get-NovaTestWorkflowContext -TestOption @{} -BoundParameters @{}

        $result.PesterConfig.CodeCoverage.Path | Should -BeNullOrEmpty
    }
}
