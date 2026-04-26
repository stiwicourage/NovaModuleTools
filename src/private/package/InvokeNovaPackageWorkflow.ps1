function Invoke-NovaPackageWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun
    )

    Invoke-NovaBuildValidation -WorkflowContext $WorkflowContext

    if (-not $ShouldRun) {
        return
    }

    return Invoke-NovaPackageArtifactCreation -WorkflowContext $WorkflowContext
}
