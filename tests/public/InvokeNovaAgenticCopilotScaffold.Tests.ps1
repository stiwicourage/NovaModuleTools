BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/InvokeNovaAgenticCopilotScaffold.ps1')

    function Get-NovaAgenticCopilotScaffoldWorkflowContext {
        param($Path, $ShortName, [switch]$OverrideWarningRequested)
        $script:ctxArgs = @{
            Path = $Path
            ShortName = $ShortName
            OverrideWarningRequested = [bool]$OverrideWarningRequested
        }
        return [pscustomobject]@{Target = $Path; Action = 'Apply'}
    }

    function Invoke-NovaAgenticCopilotScaffoldWorkflow {
        param($WorkflowContext, [switch]$ShouldRun)
        $script:workflowArgs = @{
            WorkflowContext = $WorkflowContext
            ShouldRun = [bool]$ShouldRun
        }
    }
}

Describe 'Invoke-NovaAgenticCopilotScaffold' {
    BeforeEach {
        $script:ctxArgs = $null
        $script:workflowArgs = $null
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
