BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/UpdateNovaModuleVersion.ps1')

    . (Join-Path $PSScriptRoot 'UpdateNovaModuleVersion.TestSupport.ps1')
}

Describe 'Update-NovaModuleVersion' {
    BeforeEach {
        $script:ciActivation = [pscustomobject]@{ShouldReturn=$false; Result=$null}
        $script:ctxArgs = $null; $script:invoked = $false
        $script:workflowArgs = $null
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

    It 'forwards the WhatIf preview flags to the workflow' {
        Update-NovaModuleVersion -Path . -WhatIf | Out-Null
        $script:workflowArgs.ShouldRun | Should -BeFalse
        $script:workflowArgs.WhatIfEnabled | Should -BeTrue
    }

    It 'returns nothing when the workflow returns null' {
        $script:workflowResult = $null
        Update-NovaModuleVersion -Path . | Should -BeNullOrEmpty
        $script:outputResult | Should -BeNullOrEmpty
    }

    It 'defaults Path from the current location when Path is omitted' {
        Update-NovaModuleVersion | Out-Null
        $script:ctxArgs.ProjectRoot | Should -Be (Get-Location).Path
    }
}
