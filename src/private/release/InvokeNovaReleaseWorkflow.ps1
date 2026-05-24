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
    $whatIfEnabled = Test-NovaReleaseWorkflowWhatIfEnabled -WorkflowParams $workflowParams
    $progressActivity = 'Running Nova release workflow'
    $versionResult = $null

    try {
        Invoke-NovaReleaseWorkflowStep -Activity $progressActivity -Status 'Building the current project state' -PercentComplete 15 -Action {
            Invoke-NovaBuild @buildWorkflowParams
        }

        if (-not $skipTestsRequested) {
            Invoke-NovaReleaseWorkflowStep -Activity $progressActivity -Status 'Running pre-release tests' -PercentComplete 35 -Action {
                Test-NovaBuild @testWorkflowParams
            }
        }

        $versionResult = Invoke-NovaReleaseWorkflowStep -Activity $progressActivity -Status (Get-NovaReleaseVersionStepStatus -WhatIfEnabled:$whatIfEnabled) -PercentComplete 55 -Action {
            Update-NovaModuleVersion @ciWorkflowParams
        }

        Invoke-NovaReleaseWorkflowStep -Activity $progressActivity -Status 'Rebuilding release output' -PercentComplete 75 -Action {
            Invoke-NovaBuild @buildWorkflowParams
        }

        Invoke-NovaReleaseWorkflowStep -Activity $progressActivity -Status (Get-NovaReleasePublishStepStatus -WorkflowContext $WorkflowContext -WhatIfEnabled:$whatIfEnabled) -PercentComplete 90 -Action {
            & $WorkflowContext.PublishInvocation.Action @publishParams
        }

        if ($shouldRestoreBuiltModule) {
            Invoke-NovaReleaseWorkflowStep -Activity $progressActivity -Status 'Refreshing the current session with the built module' -PercentComplete 98 -Action {
                $null = Import-NovaBuiltModuleForCi -ProjectInfo $WorkflowContext.ProjectInfo
            }
        }
    } finally {
        Write-Progress -Activity $progressActivity -Completed
    }

    Write-NovaReleaseWorkflowResult -WorkflowContext $WorkflowContext -VersionResult $versionResult -WhatIfEnabled:$whatIfEnabled -ShouldRestoreBuiltModule:$shouldRestoreBuiltModule
    return $versionResult
}

function Invoke-NovaReleaseWorkflowStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Activity,
        [Parameter(Mandatory)][string]$Status,
        [Parameter(Mandatory)][int]$PercentComplete,
        [Parameter(Mandatory)][scriptblock]$Action
    )

    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    & $Action
}

function Test-NovaReleaseWorkflowWhatIfEnabled {
    [CmdletBinding()]
    param(
        [hashtable]$WorkflowParams = @{}
    )

    return $WorkflowParams.ContainsKey('WhatIf') -and $WorkflowParams.WhatIf
}

function Get-NovaReleaseVersionStepStatus {
    [CmdletBinding()]
    param(
        [switch]$WhatIfEnabled
    )

    if ($WhatIfEnabled) {
        return 'Planning the next release version'
    }

    return 'Updating the project version'
}

function Get-NovaReleasePublishStepStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$WhatIfEnabled
    )

    $targetDescription = if ($WorkflowContext.PublishInvocation.IsLocal) {
        'the local module path'
    } else {
        "repository $( $WorkflowContext.PublishInvocation.Target )"
    }

    if ($WhatIfEnabled) {
        return "Previewing publish to $targetDescription"
    }

    return "Publishing release to $targetDescription"
}

function Write-NovaReleaseWorkflowResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [AllowNull()][object]$VersionResult,
        [switch]$WhatIfEnabled,
        [switch]$ShouldRestoreBuiltModule
    )

    $resolvedVersion = Get-NovaReleaseWorkflowResultVersion -VersionResult $VersionResult
    $statusMessage = Get-NovaReleaseWorkflowStatusMessage -ProjectInfo $WorkflowContext.ProjectInfo -Version $resolvedVersion -WhatIfEnabled:$WhatIfEnabled
    Write-Message $statusMessage -color Green
    Write-Message "Publish target: $( $WorkflowContext.PublishInvocation.Target )"

    if ($WorkflowContext.SkipTestsRequested) {
        Write-Message 'Pre-release tests were skipped for this run.'
    }

    if ($ShouldRestoreBuiltModule) {
        Write-Message 'The freshly built dist module is loaded again for later commands in this session.'
    }

    foreach ($line in (Get-NovaReleaseWorkflowNextStepLine -WorkflowContext $WorkflowContext -WhatIfEnabled:$WhatIfEnabled)) {
        Write-Message $line
    }
}

function Get-NovaReleaseWorkflowResultVersion {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$VersionResult
    )

    if ($null -eq $VersionResult) {
        return $null
    }

    if ($VersionResult.PSObject.Properties.Name -contains 'NewVersion') {
        return $VersionResult.NewVersion
    }

    if ($VersionResult.PSObject.Properties.Name -contains 'Version') {
        return $VersionResult.Version
    }

    return $null
}

function Get-NovaReleaseWorkflowStatusMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [AllowNull()][string]$Version,
        [switch]$WhatIfEnabled
    )

    if ($WhatIfEnabled) {
        if ([string]::IsNullOrWhiteSpace($Version)) {
            return "Release plan ready for $( $ProjectInfo.ProjectName )"
        }

        return "Release plan ready for $( $ProjectInfo.ProjectName ) -> $Version"
    }

    if ([string]::IsNullOrWhiteSpace($Version)) {
        return "Released Nova module: $( $ProjectInfo.ProjectName )"
    }

    return "Released Nova module: $( $ProjectInfo.ProjectName ) $Version"
}

function Get-NovaReleaseWorkflowNextStepLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$WhatIfEnabled
    )

    if ($WhatIfEnabled) {
        return @(
            'Next step:'
            'Run Invoke-NovaRelease without -WhatIf when you are ready to apply the release.'
        )
    }

    if ($WorkflowContext.PublishInvocation.IsLocal) {
        return @(
            'Next step:'
            'Get-NovaProjectInfo -Installed'
        )
    }

    return @(
        'Next step:'
        'Get-NovaProjectInfo -Version'
    )
}
