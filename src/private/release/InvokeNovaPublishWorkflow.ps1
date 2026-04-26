function Invoke-NovaPublishWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun
    )

    $publishParams = $WorkflowContext.PublishParams

    Invoke-NovaBuildValidation -WorkflowContext $WorkflowContext

    & $WorkflowContext.PublishInvocation.Action @publishParams

    if (-not $ShouldRun -or -not $WorkflowContext.LocalPublishActivation) {
        return
    }

    $null = & $WorkflowContext.LocalPublishActivation.ImportAction -ProjectName $WorkflowContext.PublishInvocation.Parameters.ProjectInfo.ProjectName -ManifestPath $WorkflowContext.LocalPublishActivation.ManifestPath
    Write-Verbose "Module copy to local path complete and imported from $( $WorkflowContext.LocalPublishActivation.ManifestPath )"
}
