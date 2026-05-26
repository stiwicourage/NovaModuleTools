function Test-NovaPublishWorkflowShouldImportLocalModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun
    )

    return $ShouldRun -and $null -ne $WorkflowContext.LocalPublishActivation
}

function Test-NovaPublishWorkflowWhatIfEnabled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    return $WorkflowContext.WorkflowParams.ContainsKey('WhatIf') -and $WorkflowContext.WorkflowParams.WhatIf
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

function Invoke-NovaPublishWorkflowStep {
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

function Invoke-NovaPublishWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun
    )

    $publishParams = $WorkflowContext.PublishParams
    $continuousIntegrationRequested = ($WorkflowContext.PSObject.Properties.Name -contains 'ContinuousIntegrationRequested') -and $WorkflowContext.ContinuousIntegrationRequested
    $shouldImportPublishedLocalModule = Test-NovaPublishWorkflowShouldImportLocalModule -WorkflowContext $WorkflowContext -ShouldRun:$ShouldRun
    $whatIfEnabled = Test-NovaPublishWorkflowWhatIfEnabled -WorkflowContext $WorkflowContext
    $progressActivity = 'Running Nova publish workflow'
    $importedLocalModule = $false
    $restoredBuiltModule = $false
    $resolvedResult = Get-NovaPublishWorkflowResolvedResult -WorkflowContext $WorkflowContext -WhatIfEnabled:$whatIfEnabled
    $messageWriter = (Get-Command -Name Write-Message -CommandType Function -ErrorAction Stop).ScriptBlock
    $resultWriter = (Get-Command -Name Write-NovaPublishWorkflowResolvedResult -CommandType Function -ErrorAction Stop).ScriptBlock

    try {
        Invoke-NovaPublishWorkflowStep -Activity $progressActivity -Status (Get-NovaPublishWorkflowValidationStatus -WorkflowContext $WorkflowContext) -PercentComplete 35 -Action {
            Invoke-NovaBuildValidation -WorkflowContext $WorkflowContext
        }

        Invoke-NovaPublishWorkflowStep -Activity $progressActivity -Status (Get-NovaPublishWorkflowPublishStatus -WorkflowContext $WorkflowContext -WhatIfEnabled:$whatIfEnabled) -PercentComplete 75 -Action {
            & $WorkflowContext.PublishInvocation.Action @publishParams
        }

        if ($shouldImportPublishedLocalModule) {
            Invoke-NovaPublishWorkflowStep -Activity $progressActivity -Status 'Importing the published local module' -PercentComplete 90 -Action {
                $null = & $WorkflowContext.LocalPublishActivation.ImportAction -ProjectName $WorkflowContext.PublishInvocation.Parameters.ProjectInfo.ProjectName -ManifestPath $WorkflowContext.LocalPublishActivation.ManifestPath
            }
            $importedLocalModule = $true
            Write-Verbose "Module copy to local path complete and imported from $( $WorkflowContext.LocalPublishActivation.ManifestPath )"
        }

        if ($ShouldRun -and $continuousIntegrationRequested) {
            Invoke-NovaPublishWorkflowStep -Activity $progressActivity -Status 'Refreshing the current session with the built module' -PercentComplete 98 -Action {
                $null = Import-NovaBuiltModuleForCi -ProjectInfo $WorkflowContext.ProjectInfo
            }
            $restoredBuiltModule = $true
        }
    } finally {
        Write-Progress -Activity $progressActivity -Completed
    }

    & $resultWriter -Result $resolvedResult -MessageWriter $messageWriter -ImportedLocalModule:$importedLocalModule -RestoredBuiltModule:$restoredBuiltModule
}

function Get-NovaPublishWorkflowValidationStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    if ($WorkflowContext.SkipTestsRequested) {
        return 'Building publish output with tests skipped'
    }

    return 'Building and testing publish output'
}

function Get-NovaPublishWorkflowPublishStatus {
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

    return "Publishing to $targetDescription"
}

function Get-NovaPublishWorkflowResolvedResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$WhatIfEnabled
    )

    $localManifestPath = $null
    if ($WorkflowContext.PSObject.Properties.Name -contains 'LocalPublishActivation') {
        $localManifestPath = Get-NovaPublishWorkflowPropertyValue -InputObject $WorkflowContext.LocalPublishActivation -Name 'ManifestPath'
    }

    return [pscustomobject]@{
        StatusMessage = Get-NovaPublishWorkflowStatusMessage -WorkflowContext $WorkflowContext -WhatIfEnabled:$WhatIfEnabled
        PublishTarget = $WorkflowContext.PublishInvocation.Target
        SkipTestsRequested = $WorkflowContext.SkipTestsRequested
        LocalManifestPath = $localManifestPath
        NextStepLines = @(Get-NovaPublishWorkflowNextStepLine -WorkflowContext $WorkflowContext -WhatIfEnabled:$WhatIfEnabled)
    }
}

function Write-NovaPublishWorkflowResolvedResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Result,
        [Parameter(Mandatory)][scriptblock]$MessageWriter,
        [switch]$ImportedLocalModule,
        [switch]$RestoredBuiltModule
    )

    & $MessageWriter $Result.StatusMessage -color Green
    & $MessageWriter "Publish target: $( $Result.PublishTarget )"

    if ($Result.SkipTestsRequested) {
        & $MessageWriter 'Pre-publish tests were skipped for this run.'
    }

    if ($ImportedLocalModule -and -not [string]::IsNullOrWhiteSpace($Result.LocalManifestPath)) {
        & $MessageWriter "The published local module is loaded from $( $Result.LocalManifestPath )."
    }

    if ($RestoredBuiltModule) {
        & $MessageWriter 'The freshly built dist module is loaded again for later commands in this session.'
    }

    foreach ($line in $Result.NextStepLines) {
        & $MessageWriter $line
    }
}

function Get-NovaPublishWorkflowStatusMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$WhatIfEnabled
    )

    if ($WhatIfEnabled) {
        return "Publish plan ready for $( $WorkflowContext.ProjectInfo.ProjectName )"
    }

    return "Published Nova module: $( $WorkflowContext.ProjectInfo.ProjectName )"
}

function Get-NovaPublishWorkflowNextStepLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$WhatIfEnabled
    )

    if ($WhatIfEnabled) {
        return @(
            'Next step:'
            'Run Publish-NovaModule without -WhatIf when you are ready to publish the module.'
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
        "Find-Module $( $WorkflowContext.ProjectInfo.ProjectName ) -Repository $( $WorkflowContext.PublishInvocation.Target )"
    )
}

function Get-NovaPublishWorkflowPropertyValue {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$InputObject,
        [Parameter(Mandatory)][string]$Name
    )

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        if ( $InputObject.Contains($Name)) {
            return $InputObject[$Name]
        }

        return $null
    }

    if ($InputObject.PSObject.Properties.Name -contains $Name) {
        return $InputObject.$Name
    }

    return $null
}
