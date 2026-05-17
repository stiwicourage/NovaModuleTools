BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/InvokeNovaBuild.ps1')

    function Get-NovaBuildWorkflowContext {param([switch]$ContinuousIntegrationRequested, [switch]$OverrideWarningRequested)
        $script:contextArgs = @{CI=[bool]$ContinuousIntegrationRequested; Override=[bool]$OverrideWarningRequested}
        return [pscustomobject]@{Target='/proj'; Operation='Build'}
    }
    function Invoke-NovaBuildWorkflow {param($WorkflowContext) $script:workflowCalled = $true}
}

Describe 'Invoke-NovaBuild' {
    BeforeEach {
        $script:contextArgs = $null
        $script:workflowCalled = $false
    }

    It 'forwards switch parameters to the workflow context' {
        Invoke-NovaBuild -ContinuousIntegration -OverrideWarning
        $script:contextArgs.CI | Should -BeTrue
        $script:contextArgs.Override | Should -BeTrue
        $script:workflowCalled | Should -BeTrue
    }

    It 'skips the workflow when -WhatIf is set' {
        Invoke-NovaBuild -WhatIf
        $script:workflowCalled | Should -BeFalse
    }
}
