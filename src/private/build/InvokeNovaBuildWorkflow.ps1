function Invoke-NovaBuildWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $projectInfo = $WorkflowContext.ProjectInfo
    $continuousIntegrationRequested = ($WorkflowContext.PSObject.Properties.Name -contains 'ContinuousIntegrationRequested') -and $WorkflowContext.ContinuousIntegrationRequested
    $overrideWarningRequested = ($WorkflowContext.PSObject.Properties.Name -contains 'OverrideWarningRequested') -and $WorkflowContext.OverrideWarningRequested
    $progressActivity = 'Building Nova module'

    try {
        Invoke-NovaBuildWorkflowStep -Activity $progressActivity -Status 'Validating public command layout' -PercentComplete 10 -Action {
            Assert-NovaPublicFunctionFileLayout -ProjectInfo $projectInfo -OverrideWarningRequested:$overrideWarningRequested
        }

        Invoke-NovaBuildWorkflowStep -Activity $progressActivity -Status 'Resetting dist output' -PercentComplete 20 -Action {
            Reset-ProjectDist -ProjectInfo $projectInfo -Confirm:$false
        }

        Invoke-NovaBuildWorkflowStep -Activity $progressActivity -Status 'Building module output' -PercentComplete 35 -Action {
            Build-Module -ProjectInfo $projectInfo
        }

        Invoke-NovaBuildWorkflowStep -Activity $progressActivity -Status 'Validating duplicate function names' -PercentComplete 50 -Action {
            Invoke-NovaBuildDuplicateValidation -ProjectInfo $projectInfo
        }

        Invoke-NovaBuildWorkflowStep -Activity $progressActivity -Status 'Writing module manifest' -PercentComplete 65 -Action {
            Build-Manifest -ProjectInfo $projectInfo
        }

        Invoke-NovaBuildWorkflowStep -Activity $progressActivity -Status 'Building command help' -PercentComplete 78 -Action {
            Build-Help -ProjectInfo $projectInfo
        }

        Invoke-NovaBuildWorkflowStep -Activity $progressActivity -Status 'Copying project resources' -PercentComplete 88 -Action {
            Copy-ProjectResource -ProjectInfo $projectInfo
        }

        Invoke-NovaBuildWorkflowStep -Activity $progressActivity -Status 'Checking update notifications' -PercentComplete 94 -Action {
            Invoke-NovaModuleUpdateNotificationSafely
        }

        if ($continuousIntegrationRequested) {
            Write-NovaBuildWorkflowResult -ProjectInfo $projectInfo

            Invoke-NovaBuildWorkflowStep -Activity $progressActivity -Status 'Refreshing the current session with the built module' -PercentComplete 98 -Action {
                $null = Import-NovaBuiltModuleForCi -ProjectInfo $projectInfo
            }

            return
        }
    } finally {
        Write-Progress -Activity $progressActivity -Completed
    }

    Write-NovaBuildWorkflowResult -ProjectInfo $projectInfo
}

function Invoke-NovaBuildWorkflowStep {
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

function Write-NovaBuildWorkflowResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    Write-Message "Built Nova module: $( $ProjectInfo.ProjectName )" -color Green
    Write-Message "Output module: $( $ProjectInfo.OutputModuleDir )"
    Write-Message 'Next step: Test-NovaBuild'
}

function Invoke-NovaBuildDuplicateValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    if (-not $ProjectInfo.FailOnDuplicateFunctionNames) {
        return
    }

    Assert-BuiltModuleHasNoDuplicateFunctionName -ProjectInfo $ProjectInfo
}
