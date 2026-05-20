BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/InvokeNovaAgenticCopilotScaffold.ps1')
    . (Join-Path $PSScriptRoot 'InvokeNovaAgenticCopilotScaffold.TestSupport.ps1')
}

Describe 'Invoke-NovaAgenticCopilotScaffold' {
    BeforeEach {
        $script:ctxArgs = $null
        $script:workflowArgs = $null
    }

    It 'defaults Path to the current location when Path is omitted' {
        Invoke-NovaAgenticCopilotScaffold -ShortName 'NMT'

        $script:ctxArgs.Path | Should -Be (Get-Location).Path
        $script:workflowArgs.ShouldRun | Should -BeTrue
    }

    It 'forwards Path, ShortName, and OverrideWarning to the workflow context' {
        Invoke-NovaAgenticCopilotScaffold -Path '/tmp/project' -ShortName 'NMT' -OverrideWarning

        $script:ctxArgs.Path | Should -Be '/tmp/project'
        $script:ctxArgs.ShortName | Should -Be 'NMT'
        $script:ctxArgs.OverrideWarningRequested | Should -BeTrue
        $script:workflowArgs.ShouldRun | Should -BeTrue
    }

    It 'invokes the workflow in WhatIf mode with ShouldRun disabled' {
        Invoke-NovaAgenticCopilotScaffold -Path '/tmp/project' -ShortName 'NMT' -WhatIf

        $script:workflowArgs.ShouldRun | Should -BeFalse
    }
}
