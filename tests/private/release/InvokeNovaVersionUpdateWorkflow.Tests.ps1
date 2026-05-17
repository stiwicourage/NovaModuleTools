BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/InvokeNovaVersionUpdateWorkflow.ps1')

    function Set-NovaModuleVersion {param($ProjectInfo, $Label, [switch]$PreviewRelease, [switch]$Confirm) return [pscustomobject]@{Applied=$true}}
}

Describe 'Test-NovaVersionUpdateResultRequired' {
    It 'returns true when ShouldRun is set' {
        Test-NovaVersionUpdateResultRequired -ShouldRun | Should -BeTrue
    }

    It 'returns true when WhatIfEnabled is set' {
        Test-NovaVersionUpdateResultRequired -WhatIfEnabled | Should -BeTrue
    }

    It 'returns false when neither is set' {
        Test-NovaVersionUpdateResultRequired | Should -BeFalse
    }
}

Describe 'Get-NovaVersionUpdateEffectiveLabel' {
    It 'prefers EffectiveLabel when present and non-empty' {
        Get-NovaVersionUpdateEffectiveLabel -WorkflowContext ([pscustomobject]@{Label='Patch'; EffectiveLabel='Minor'}) | Should -Be 'Minor'
    }

    It 'falls back to Label when EffectiveLabel is missing' {
        Get-NovaVersionUpdateEffectiveLabel -WorkflowContext ([pscustomobject]@{Label='Patch'}) | Should -Be 'Patch'
    }
}

Describe 'Get-NovaVersionUpdateAdvisoryMessage' {
    It 'returns $null when AdvisoryMessage is missing' {
        Get-NovaVersionUpdateAdvisoryMessage -WorkflowContext ([pscustomobject]@{Other=1}) | Should -BeNullOrEmpty
    }

    It 'returns the message when present' {
        Get-NovaVersionUpdateAdvisoryMessage -WorkflowContext ([pscustomobject]@{AdvisoryMessage='hi'}) | Should -Be 'hi'
    }
}

Describe 'Get-NovaVersionUpdateResult' {
    It 'assembles a structured result' {
        $ctx = [pscustomobject]@{PreviousVersion='1.0.0'; NewVersion='1.0.1'; Label='Patch'; CommitCount=2}
        $result = Get-NovaVersionUpdateResult -WorkflowContext $ctx -Applied
        $result.PreviousVersion | Should -Be '1.0.0'
        $result.NewVersion | Should -Be '1.0.1'
        $result.Label | Should -Be 'Patch'
        $result.EffectiveLabel | Should -Be 'Patch'
        $result.CommitCount | Should -Be 2
        $result.Applied | Should -BeTrue
    }
}
