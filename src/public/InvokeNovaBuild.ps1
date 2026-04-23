function Invoke-NovaBuild {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
    )
    $workflowContext = Get-NovaBuildWorkflowContext

    if (-not $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Operation)) {
        return
    }

    Invoke-NovaBuildWorkflow -WorkflowContext $workflowContext
}
