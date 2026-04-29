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
        [switch]$ContinuousIntegrationRequested,
        [scriptblock]$ImportBuiltModuleForCiAction = ${function:Import-NovaBuiltModuleForCi}
    )

    if ($ShouldRun -and $ContinuousIntegrationRequested) {
        $null = & $ImportBuiltModuleForCiAction -ProjectInfo $WorkflowContext.ProjectInfo
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
    $ciRestoreAction = ${function:Invoke-NovaPublishWorkflowCiRestore}
    $importBuiltModuleForCiAction = ${function:Import-NovaBuiltModuleForCi}

    Invoke-NovaBuildValidation -WorkflowContext $WorkflowContext

    & $WorkflowContext.PublishInvocation.Action @publishParams

    if (-not $shouldImportPublishedLocalModule) {
        & $ciRestoreAction -WorkflowContext $WorkflowContext -ShouldRun:$ShouldRun -ContinuousIntegrationRequested:$continuousIntegrationRequested -ImportBuiltModuleForCiAction $importBuiltModuleForCiAction
        return
    }

    $null = & $WorkflowContext.LocalPublishActivation.ImportAction -ProjectName $WorkflowContext.PublishInvocation.Parameters.ProjectInfo.ProjectName -ManifestPath $WorkflowContext.LocalPublishActivation.ManifestPath
    Write-Verbose "Module copy to local path complete and imported from $( $WorkflowContext.LocalPublishActivation.ManifestPath )"

    & $ciRestoreAction -WorkflowContext $WorkflowContext -ShouldRun:$ShouldRun -ContinuousIntegrationRequested:$continuousIntegrationRequested -ImportBuiltModuleForCiAction $importBuiltModuleForCiAction
}
