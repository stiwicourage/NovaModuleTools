function Invoke-NovaPackageWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun
    )

    $workflowParams = $WorkflowContext.WorkflowParams

    Invoke-NovaBuild @workflowParams
    Test-NovaBuild @workflowParams

    if (-not $ShouldRun) {
        return
    }

    return Invoke-NovaPackageArtifactCreation -WorkflowContext $WorkflowContext
}
