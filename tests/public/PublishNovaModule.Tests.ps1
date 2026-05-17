BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/PublishNovaModule.ps1')

    function Get-NovaDynamicDeliveryParameterDictionary {return New-Object 'System.Management.Automation.RuntimeDefinedParameterDictionary'}
    function Get-NovaProjectInfo {return [pscustomobject]@{Name='X'}}
    function Get-NovaShouldProcessForwardingParameter {param([switch]$WhatIfEnabled) return @{WhatIf=[bool]$WhatIfEnabled}}
    function Get-NovaPublishWorkflowContext {param($ProjectInfo, $PublishOption, $WorkflowParams, $WorkflowSettings)
        $script:publishOption = $PublishOption
        $script:settings = $WorkflowSettings
        return [pscustomobject]@{Target='nuget.org'; Operation='Publish'}
    }
    function Write-NovaPublishWorkflowContext {param($WorkflowContext) $script:wrote = $true}
    function Invoke-NovaPublishWorkflow {param($WorkflowContext, [switch]$ShouldRun)
        $script:invoked = $true
        $script:shouldRun = [bool]$ShouldRun
    }
}

Describe 'Publish-NovaModule' {
    BeforeEach {
        $script:publishOption = $null; $script:settings = $null
        $script:wrote = $false; $script:invoked = $false; $script:shouldRun = $null
    }

    It 'builds the local publish option and invokes the publish workflow' {
        Publish-NovaModule -Local
        $script:publishOption.Local | Should -BeTrue
        $script:settings.WorkflowName | Should -Be 'publish'
        $script:settings.IncludeLocalPublishActivation | Should -BeTrue
        $script:wrote | Should -BeTrue
        $script:invoked | Should -BeTrue
    }

    It 'invokes the publish workflow with ShouldRun=$false when -WhatIf is set' {
        Publish-NovaModule -Local -WhatIf
        $script:invoked | Should -BeTrue
        $script:shouldRun | Should -BeFalse
    }

    It 'forwards Repository, ModuleDirectoryPath, and ApiKey to the publish option' {
        Publish-NovaModule -Repository 'Nexus' -ModuleDirectoryPath '/d' -ApiKey 'k'
        $script:publishOption.Repository | Should -Be 'Nexus'
        $script:publishOption.ModuleDirectoryPath | Should -Be '/d'
        $script:publishOption.ApiKey | Should -Be 'k'
    }
}
