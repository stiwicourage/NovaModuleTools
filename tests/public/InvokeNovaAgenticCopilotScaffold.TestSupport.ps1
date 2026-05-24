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
