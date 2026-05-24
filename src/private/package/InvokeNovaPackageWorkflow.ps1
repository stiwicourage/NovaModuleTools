function Invoke-NovaPackageWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun
    )

    $whatIfEnabled = Test-NovaPackageWorkflowWhatIfEnabled -WorkflowContext $WorkflowContext
    $progressActivity = 'Creating Nova package artifacts'

    try {
        Invoke-NovaPackageWorkflowStep -Activity $progressActivity -Status (Get-NovaPackageValidationStatus -WorkflowContext $WorkflowContext) -PercentComplete 30 -Action {
            Invoke-NovaBuildValidation -WorkflowContext $WorkflowContext
        }

        if (-not $ShouldRun) {
            if ($whatIfEnabled) {
                Write-NovaPackageWorkflowResult -WorkflowContext $WorkflowContext -WhatIfEnabled
            }

            return
        }

        $artifacts = Invoke-NovaPackageWorkflowStep -Activity $progressActivity -Status 'Creating package artifacts' -PercentComplete 85 -Action {
            Invoke-NovaPackageArtifactCreation -WorkflowContext $WorkflowContext
        }
    } finally {
        Write-Progress -Activity $progressActivity -Completed
    }

    Write-NovaPackageWorkflowResult -WorkflowContext $WorkflowContext -Artifacts $artifacts
    return $artifacts
}

function Invoke-NovaPackageWorkflowStep {
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

function Test-NovaPackageWorkflowWhatIfEnabled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    return ($WorkflowContext.WorkflowParams.ContainsKey('WhatIf') -and $WorkflowContext.WorkflowParams.WhatIf)
}

function Get-NovaPackageValidationStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    if ($WorkflowContext.SkipTestsRequested) {
        return 'Building package input with tests skipped'
    }

    return 'Building and testing package input'
}

function Write-NovaPackageWorkflowResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [AllowNull()][AllowEmptyCollection()][object[]]$Artifacts = @(),
        [switch]$WhatIfEnabled
    )

    $resolvedArtifacts = @($Artifacts)
    $statusMessage = Get-NovaPackageWorkflowStatusMessage -WorkflowContext $WorkflowContext -ArtifactCount $resolvedArtifacts.Count -WhatIfEnabled:$WhatIfEnabled
    Write-Message $statusMessage -color Green
    Write-Message "Package target: $( Get-NovaPackageWorkflowResultTarget -WorkflowContext $WorkflowContext -Artifacts $resolvedArtifacts -WhatIfEnabled:$WhatIfEnabled )"

    foreach ($line in (Get-NovaPackageWorkflowNextStepLine -WhatIfEnabled:$WhatIfEnabled)) {
        Write-Message $line
    }
}

function Get-NovaPackageWorkflowStatusMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [Parameter(Mandatory)][int]$ArtifactCount,
        [switch]$WhatIfEnabled
    )

    if ($WhatIfEnabled) {
        return "Package plan ready for $( $WorkflowContext.ProjectInfo.ProjectName )"
    }

    if ($ArtifactCount -eq 1) {
        return "Created 1 package artifact for $( $WorkflowContext.ProjectInfo.ProjectName )"
    }

    return "Created $ArtifactCount package artifacts for $( $WorkflowContext.ProjectInfo.ProjectName )"
}

function Get-NovaPackageWorkflowResultTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Artifacts,
        [switch]$WhatIfEnabled
    )

    if ($WhatIfEnabled) {
        return $WorkflowContext.Target
    }

    $resolvedOutputDirectories = @($Artifacts | ForEach-Object OutputDirectory | Sort-Object -Unique)
    if ($resolvedOutputDirectories.Count -eq 0) {
        return $WorkflowContext.Target
    }

    return ($resolvedOutputDirectories -join ', ')
}

function Get-NovaPackageWorkflowNextStepLine {
    [CmdletBinding()]
    param(
        [switch]$WhatIfEnabled
    )

    if ($WhatIfEnabled) {
        return @(
            'Next step:'
            'Run New-NovaModulePackage without -WhatIf when you are ready to create the package artifacts.'
        )
    }

    return @(
        'Next step:'
        'Deploy-NovaPackage'
    )
}
