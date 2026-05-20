function Invoke-NovaAgenticCopilotScaffold {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string]$Path = (Get-Location).Path,
        [Parameter(Mandatory)][string]$ShortName,
        [switch]$OverrideWarning
    )

    $workflowContext = Get-NovaAgenticCopilotScaffoldWorkflowContext -Path $Path -ShortName $ShortName -OverrideWarningRequested:$OverrideWarning
    $shouldRun = $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Action)
    if (-not $shouldRun -and -not $WhatIfPreference) {
        return
    }

    Invoke-NovaAgenticCopilotScaffoldWorkflow -WorkflowContext $workflowContext -ShouldRun:$shouldRun
}
