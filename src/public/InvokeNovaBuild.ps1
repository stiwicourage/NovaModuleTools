function Invoke-NovaBuild {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [switch]$ContinuousIntegration,
        [switch]$OverrideWarning
    )

    $workflowContext = Get-NovaBuildWorkflowContext -ContinuousIntegrationRequested:$ContinuousIntegration -OverrideWarningRequested:$OverrideWarning

    if (-not $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Operation)) {
        return
    }

    Invoke-NovaBuildWorkflow -WorkflowContext $workflowContext
}
