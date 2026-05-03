function Get-NovaReleaseNestedWorkflowParameterMap {
    [CmdletBinding()]
    param(
        [hashtable]$WorkflowParams = @{},
        [switch]$ContinuousIntegrationRequested
    )

    $nestedWorkflowParams = @{}
    foreach ($parameterName in $WorkflowParams.Keys) {
        $nestedWorkflowParams[$parameterName] = $WorkflowParams[$parameterName]
    }

    if ($ContinuousIntegrationRequested) {
        $nestedWorkflowParams.ContinuousIntegration = $true
    }

    return $nestedWorkflowParams
}

function Test-NovaReleaseWorkflowShouldRestoreBuiltModule {
    [CmdletBinding()]
    param(
        [hashtable]$WorkflowParams = @{},
        [switch]$ContinuousIntegrationRequested
    )

    return $ContinuousIntegrationRequested -and -not ($WorkflowParams.ContainsKey('WhatIf') -and $WorkflowParams.WhatIf)
}

function Invoke-NovaReleaseWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $continuousIntegrationRequested = ($WorkflowContext.PSObject.Properties.Name -contains 'ContinuousIntegrationRequested') -and $WorkflowContext.ContinuousIntegrationRequested
    $skipTestsRequested = ($WorkflowContext.PSObject.Properties.Name -contains 'SkipTestsRequested') -and $WorkflowContext.SkipTestsRequested
    $workflowParams = $WorkflowContext.WorkflowParams
    $ciWorkflowParams = Get-NovaReleaseNestedWorkflowParameterMap -WorkflowParams $workflowParams -ContinuousIntegrationRequested:$continuousIntegrationRequested
    $shouldRestoreBuiltModule = Test-NovaReleaseWorkflowShouldRestoreBuiltModule -WorkflowParams $workflowParams -ContinuousIntegrationRequested:$continuousIntegrationRequested
    $publishParams = $WorkflowContext.PublishParams

    Invoke-NovaBuild @ciWorkflowParams
    if (-not $skipTestsRequested) {
        Test-NovaBuild @workflowParams
    }

    $versionResult = Update-NovaModuleVersion @ciWorkflowParams
    Invoke-NovaBuild @ciWorkflowParams

    & $WorkflowContext.PublishInvocation.Action @publishParams

    if ($shouldRestoreBuiltModule) {
        $null = Import-NovaBuiltModuleForCi -ProjectInfo $WorkflowContext.ProjectInfo
    }

    return $versionResult
}
