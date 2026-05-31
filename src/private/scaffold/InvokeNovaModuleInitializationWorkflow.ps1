function Invoke-NovaModuleInitializationWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $progressActivity = 'Creating Nova module scaffold'

    try {
        Invoke-NovaModuleInitializationStep -Activity $progressActivity -Status 'Creating scaffold files' -PercentComplete 25 -Action {
            Initialize-NovaModuleScaffold -Answer $WorkflowContext.AnswerSet -Paths $WorkflowContext.Layout -Example:$WorkflowContext.Example
        }

        Invoke-NovaModuleInitializationStep -Activity $progressActivity -Status 'Writing project.json' -PercentComplete 60 -Action {
            Write-NovaModuleProjectJson -Answer $WorkflowContext.AnswerSet -ProjectJsonFile $WorkflowContext.Layout.ProjectJsonFile -Example:$WorkflowContext.Example
        }

        Invoke-NovaModuleInitializationStep -Activity $progressActivity -Status 'Writing VS Code settings' -PercentComplete 75 -Action {
            Write-NovaVsCodeSettings -ProjectRoot $WorkflowContext.Layout.Project
        }

        if ($WorkflowContext.AnswerSet.EnableAgenticCopilot -eq 'Yes') {
            Invoke-NovaModuleInitializationStep -Activity $progressActivity -Status 'Applying Agentic Copilot starter' -PercentComplete 85 -Action {
                Initialize-NovaModuleAgenticCopilotScaffold -Answer $WorkflowContext.AnswerSet -ProjectRoot $WorkflowContext.Layout.Project -Example:$WorkflowContext.Example
            }
        }
    } finally {
        Write-Progress -Activity $progressActivity -Completed
    }

    Write-NovaModuleInitializationResult -WorkflowContext $WorkflowContext
}

function Invoke-NovaModuleInitializationStep {
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

function Write-NovaModuleInitializationResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    Write-Message ("Created Nova module scaffold: $( $WorkflowContext.AnswerSet.ProjectName )") -color Green
    Write-Message ("Project root: $( $WorkflowContext.Layout.Project )")

    foreach ($line in (Get-NovaModuleInitializationNextStepLine -WorkflowContext $WorkflowContext)) {
        Write-Message $line
    }
}

function Get-NovaModuleInitializationNextStepLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $nextSteps = @(
        'Next steps:'
        "Set-Location $( $WorkflowContext.Layout.Project )"
    )

    if ($WorkflowContext.Example) {
        $nextSteps += 'Invoke-NovaTest'
        $nextSteps += 'Test-NovaBuild'
        return $nextSteps
    }

    $nextSteps += 'Invoke-NovaBuild'
    return $nextSteps
}
