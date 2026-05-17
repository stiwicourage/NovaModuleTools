BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/UpdateNovaModuleVersion.ps1')

    function Invoke-NovaVersionUpdateCiActivation {param($ProjectRoot, $Parameters, [switch]$ContinuousIntegration, [switch]$WhatIfEnabled)
        return $script:ciActivation
    }
    function Get-NovaVersionUpdateWorkflowContext {param($ProjectRoot, [switch]$PreviewRelease, [switch]$ContinuousIntegrationRequested, [switch]$OverrideWarningRequested)
        $script:ctxArgs = @{Preview=[bool]$PreviewRelease; CI=[bool]$ContinuousIntegrationRequested; Override=[bool]$OverrideWarningRequested}
        return [pscustomobject]@{Target=$ProjectRoot; Action='Bump'}
    }
    function Invoke-NovaVersionUpdateWorkflow {param($WorkflowContext, [switch]$ShouldRun, [switch]$WhatIfEnabled)
        $script:invoked = $true
        return $script:workflowResult
    }
    function Write-NovaVersionUpdateResultOutput {param($Result) $script:outputResult = $Result}
}

Describe 'Update-NovaModuleVersion' {
    BeforeEach {
        $script:ciActivation = [pscustomobject]@{ShouldReturn=$false; Result=$null}
        $script:ctxArgs = $null; $script:invoked = $false
        $script:workflowResult = [pscustomobject]@{NewVersion='1.1.0'}
        $script:outputResult = $null
    }

    It 'short-circuits when CI activation requests a return' {
        $script:ciActivation = [pscustomobject]@{ShouldReturn=$true; Result='ci-result'}
        Update-NovaModuleVersion -Path . | Should -Be 'ci-result'
        $script:invoked | Should -BeFalse
    }

    It 'runs the workflow and writes the result when CI activation passes through' {
        $result = Update-NovaModuleVersion -Path . -Preview
        $script:ctxArgs.Preview | Should -BeTrue
        $script:invoked | Should -BeTrue
        $script:outputResult.NewVersion | Should -Be '1.1.0'
        $result.NewVersion | Should -Be '1.1.0'
    }

    It 'returns nothing when the workflow returns null' {
        $script:workflowResult = $null
        Update-NovaModuleVersion -Path . | Should -BeNullOrEmpty
        $script:outputResult | Should -BeNullOrEmpty
    }
}
