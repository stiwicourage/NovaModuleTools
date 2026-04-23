function Invoke-NovaPublishWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun
    )

    $workflowParams = $WorkflowContext.WorkflowParams
    $publishParams = $WorkflowContext.PublishParams

    Invoke-NovaBuild @workflowParams
    Test-NovaBuild @workflowParams

    & $WorkflowContext.PublishInvocation.Action @publishParams

    if (-not $ShouldRun -or -not $WorkflowContext.LocalPublishActivation) {
        return
    }

    $null = & $WorkflowContext.LocalPublishActivation.ImportAction -ProjectName $WorkflowContext.PublishInvocation.Parameters.ProjectInfo.ProjectName -ManifestPath $WorkflowContext.LocalPublishActivation.ManifestPath
    Write-Verbose "Module copy to local path complete and imported from $( $WorkflowContext.LocalPublishActivation.ManifestPath )"
}
