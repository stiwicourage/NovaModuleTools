BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/InitializeNovaModule.ps1')

    function Get-NovaModuleInitializationWorkflowContext {param($Path, [switch]$Example)
        $script:ctxArgs = @{Path=$Path; Example=[bool]$Example}
        return [pscustomobject]@{Target=$Path; Action='Initialize'}
    }
    function Invoke-NovaModuleInitializationWorkflow {param($WorkflowContext) $script:workflowCalled = $true}
}

Describe 'Initialize-NovaModule' {
    BeforeEach {$script:ctxArgs = $null; $script:workflowCalled = $false}

    It 'forwards Path and Example to the workflow context' {
        Initialize-NovaModule -Path '/tmp/x' -Example
        $script:ctxArgs.Path | Should -Be '/tmp/x'
        $script:ctxArgs.Example | Should -BeTrue
        $script:workflowCalled | Should -BeTrue
    }

    It 'returns without invoking the workflow when -WhatIf is set' {
        Initialize-NovaModule -Path '/tmp/x' -WhatIf
        $script:workflowCalled | Should -BeFalse
    }

    It 'defaults Path from the current location when Path is omitted' {
        Initialize-NovaModule
        $script:ctxArgs.Path | Should -Be (Get-Location).Path
    }
}
