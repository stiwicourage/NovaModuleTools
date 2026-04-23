function Invoke-NovaReleaseWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $workflowParams = $WorkflowContext.WorkflowParams
    $publishParams = $WorkflowContext.PublishParams

    Invoke-NovaBuild @workflowParams
    Test-NovaBuild @workflowParams
    $versionResult = Update-NovaModuleVersion @workflowParams
    Invoke-NovaBuild @workflowParams

    & $WorkflowContext.PublishInvocation.Action @publishParams

    return $versionResult
}
