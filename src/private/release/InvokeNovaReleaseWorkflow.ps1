function Invoke-NovaReleaseWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $workflowParams = $WorkflowContext.WorkflowParams
    $publishParams = $WorkflowContext.PublishParams

    Invoke-NovaBuildValidation -WorkflowContext $WorkflowContext
    $versionResult = Update-NovaModuleVersion @workflowParams
    Invoke-NovaBuild @workflowParams

    & $WorkflowContext.PublishInvocation.Action @publishParams

    return $versionResult
}
