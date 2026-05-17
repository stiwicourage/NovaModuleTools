BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/InvokeNovaRelease.ps1')

    function Get-NovaDynamicReleaseParameterDictionary {return New-Object 'System.Management.Automation.RuntimeDefinedParameterDictionary'}
    function Get-NovaReleaseRequestedPath {param($BoundParameters) return (Get-Location).Path}
    function Get-NovaReleaseRequest {param($BoundParameters, $ParameterSetName)
        $script:parameterSet = $ParameterSetName
        return [pscustomobject]@{ParameterSetName=$ParameterSetName}
    }
    function Get-NovaReleasePublishOption {param($ReleaseParameters) return [pscustomobject]@{Local=$true}}
    function Get-NovaProjectInfo {return [pscustomobject]@{Name='X'}}
    function Get-NovaShouldProcessForwardingParameter {param([switch]$WhatIfEnabled) return @{WhatIf=[bool]$WhatIfEnabled}}
    function Get-NovaPublishWorkflowContext {param($ProjectInfo, $PublishOption, $WorkflowParams, $WorkflowSettings)
        $script:settings = $WorkflowSettings
        return [pscustomobject]@{Target='nuget.org'; Operation='Release'}
    }
    function Write-NovaPublishWorkflowContext {param($WorkflowContext) $script:wrote = $true}
    function Invoke-NovaReleaseWorkflow {param($WorkflowContext)
        $script:invoked = $true
        return [pscustomobject]@{Released=$true}
    }
}

Describe 'Invoke-NovaRelease' {
    BeforeEach {
        $script:parameterSet = $null; $script:settings = $null
        $script:wrote = $false; $script:invoked = $false
    }

    It 'runs the release workflow with release-flavored settings' {
        $result = Invoke-NovaRelease -Local
        $script:parameterSet | Should -Be 'Local'
        $script:settings.WorkflowName | Should -Be 'release'
        $script:settings.Release | Should -BeTrue
        $script:wrote | Should -BeTrue
        $script:invoked | Should -BeTrue
        $result.Released | Should -BeTrue
    }

    It 'still invokes the release workflow when -WhatIf is set so it can render its plan' {
        Invoke-NovaRelease -Local -WhatIf | Out-Null
        $script:invoked | Should -BeTrue
    }
}
