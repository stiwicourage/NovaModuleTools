function Test-NovaPublishWorkflowShouldImportLocalModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun
    )

    return $ShouldRun -and $null -ne $WorkflowContext.LocalPublishActivation
}

function Invoke-NovaPublishWorkflowCiRestore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun,
        [switch]$ContinuousIntegrationRequested
    )

    if ($ShouldRun -and $ContinuousIntegrationRequested) {
        $null = Import-NovaBuiltModuleForCi -ProjectInfo $WorkflowContext.ProjectInfo
    }
}

function Invoke-NovaPublishWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun
    )

    $publishParams = $WorkflowContext.PublishParams
    $continuousIntegrationRequested = ($WorkflowContext.PSObject.Properties.Name -contains 'ContinuousIntegrationRequested') -and $WorkflowContext.ContinuousIntegrationRequested
    $shouldImportPublishedLocalModule = Test-NovaPublishWorkflowShouldImportLocalModule -WorkflowContext $WorkflowContext -ShouldRun:$ShouldRun

    Invoke-NovaBuildValidation -WorkflowContext $WorkflowContext

    & $WorkflowContext.PublishInvocation.Action @publishParams

    if (-not $shouldImportPublishedLocalModule) {
        Invoke-NovaPublishWorkflowCiRestore -WorkflowContext $WorkflowContext -ShouldRun:$ShouldRun -ContinuousIntegrationRequested:$continuousIntegrationRequested
        return
    }

    $null = & $WorkflowContext.LocalPublishActivation.ImportAction -ProjectName $WorkflowContext.PublishInvocation.Parameters.ProjectInfo.ProjectName -ManifestPath $WorkflowContext.LocalPublishActivation.ManifestPath
    Write-Verbose "Module copy to local path complete and imported from $( $WorkflowContext.LocalPublishActivation.ManifestPath )"

    Invoke-NovaPublishWorkflowCiRestore -WorkflowContext $WorkflowContext -ShouldRun:$ShouldRun -ContinuousIntegrationRequested:$continuousIntegrationRequested
}
