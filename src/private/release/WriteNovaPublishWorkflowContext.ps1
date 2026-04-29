function Write-NovaPublishWorkflowContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    Write-NovaLocalWorkflowMode -WorkflowName $WorkflowContext.WorkflowName -LocalRequested:$WorkflowContext.LocalRequested
    Write-NovaResolvedLocalPublishTarget -PublishInvocation $WorkflowContext.PublishInvocation
}
