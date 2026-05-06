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

function Get-NovaReleaseBuildWorkflowParameterMap {
    [CmdletBinding()]
    param(
        [hashtable]$WorkflowParams = @{},
        [switch]$OverrideWarningRequested
    )

    return Get-NovaBuildCommandParameterMap -WorkflowParams $WorkflowParams -OverrideWarningRequested:$OverrideWarningRequested
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
    $overrideWarningRequested = ($WorkflowContext.PSObject.Properties.Name -contains 'OverrideWarningRequested') -and $WorkflowContext.OverrideWarningRequested
    $workflowParams = $WorkflowContext.WorkflowParams
    $ciWorkflowParams = Get-NovaReleaseNestedWorkflowParameterMap -WorkflowParams $workflowParams -ContinuousIntegrationRequested:$continuousIntegrationRequested
    $buildWorkflowParams = Get-NovaReleaseBuildWorkflowParameterMap -WorkflowParams $ciWorkflowParams -OverrideWarningRequested:$overrideWarningRequested
    $testWorkflowParams = Get-NovaReleaseBuildWorkflowParameterMap -WorkflowParams $workflowParams -OverrideWarningRequested:$overrideWarningRequested
    $shouldRestoreBuiltModule = Test-NovaReleaseWorkflowShouldRestoreBuiltModule -WorkflowParams $workflowParams -ContinuousIntegrationRequested:$continuousIntegrationRequested
    $publishParams = $WorkflowContext.PublishParams

    Invoke-NovaBuild @buildWorkflowParams
    if (-not $skipTestsRequested) {
        Test-NovaBuild @testWorkflowParams
    }

    $versionResult = Update-NovaModuleVersion @ciWorkflowParams
    Invoke-NovaBuild @buildWorkflowParams

    & $WorkflowContext.PublishInvocation.Action @publishParams

    if ($shouldRestoreBuiltModule) {
        $null = Import-NovaBuiltModuleForCi -ProjectInfo $WorkflowContext.ProjectInfo
    }

    return $versionResult
}
