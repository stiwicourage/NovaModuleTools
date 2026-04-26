function Invoke-NovaBuild {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [switch]$ContinuousIntegration
    )

    $workflowContext = Get-NovaBuildWorkflowContext -ContinuousIntegrationRequested:$ContinuousIntegration

    if (-not $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Operation)) {
        return
    }

    Invoke-NovaBuildWorkflow -WorkflowContext $workflowContext
}
