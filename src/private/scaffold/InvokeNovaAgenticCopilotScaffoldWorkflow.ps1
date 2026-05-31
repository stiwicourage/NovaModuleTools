function Get-NovaAgenticCopilotScaffoldWarningMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $messageLines = @(
        "Nova will apply the managed Agentic Copilot scaffold in $( $WorkflowContext.ProjectRoot )."
        ''
        'These paths will be overwritten:'
    )
    $messageLines += @($WorkflowContext.ManagedOverwritePathList | ForEach-Object {"- $_"})
    $messageLines += @(
        ''
        'These files will only be created when missing:'
    )
    $messageLines += @($WorkflowContext.AddOnlyPathList | ForEach-Object {"- $_"})
    return $messageLines -join [Environment]::NewLine
}

function Read-NovaAgenticCopilotScaffoldWarningChoice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [Parameter()][object]$HostUi = $Host.UI
    )

    $choices = [System.Management.Automation.Host.ChoiceDescription[]]@(
        [System.Management.Automation.Host.ChoiceDescription]::new('&Yes', 'Apply the scaffold.'),
        [System.Management.Automation.Host.ChoiceDescription]::new('&No', 'Cancel the operation.')
    )

    return $HostUi.PromptForChoice('Confirm', $Message, $choices, 1)
}

function Confirm-NovaAgenticCopilotScaffoldWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    if ($WorkflowContext.OverrideWarningRequested) {
        Write-Verbose 'Continuing Agentic Copilot scaffold apply because OverrideWarning was specified.'
        return
    }

    $selection = Read-NovaAgenticCopilotScaffoldWarningChoice -Message (Get-NovaAgenticCopilotScaffoldWarningMessage -WorkflowContext $WorkflowContext)
    if ($selection -eq 0) {
        return
    }

    Stop-NovaOperation -Message "Agentic Copilot scaffold apply cancelled for $( $WorkflowContext.ProjectRoot ). Re-run the command and choose Yes when you are ready to overwrite the managed scaffold paths." -ErrorId 'Nova.Workflow.AgenticCopilotScaffoldCancelled' -Category OperationStopped -TargetObject $WorkflowContext.ProjectRoot
}

function Invoke-NovaAgenticCopilotScaffoldWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$ShouldRun
    )

    if (-not $ShouldRun) {
        return
    }

    $progressActivity = 'Applying Agentic Copilot scaffold'

    try {
        Invoke-NovaAgenticCopilotScaffoldStep -Activity $progressActivity -Status 'Confirming overwrite warning' -PercentComplete 20 -Action {
            Confirm-NovaAgenticCopilotScaffoldWarning -WorkflowContext $WorkflowContext
        }

        Invoke-NovaAgenticCopilotScaffoldStep -Activity $progressActivity -Status 'Refreshing managed scaffold files' -PercentComplete 75 -Action {
            Initialize-NovaModuleAgenticCopilotScaffold -Answer $WorkflowContext.AnswerSet -ProjectRoot $WorkflowContext.ProjectRoot -ScaffoldPolicy $WorkflowContext.ScaffoldPolicy
        }
    } finally {
        Write-Progress -Activity $progressActivity -Completed
    }

    Write-NovaAgenticCopilotScaffoldResult -WorkflowContext $WorkflowContext
}

function Invoke-NovaAgenticCopilotScaffoldStep {
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

function Write-NovaAgenticCopilotScaffoldResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    Write-Message "Agentic Copilot scaffold applied to $( $WorkflowContext.ProjectInfo.ProjectName )" -color Green
    Write-Message "Project root: $( $WorkflowContext.ProjectRoot )"

    foreach ($line in (Get-NovaAgenticCopilotScaffoldNextStepLine)) {
        Write-Message $line
    }
}

function Get-NovaAgenticCopilotScaffoldNextStepLine {
    return @(
        'Next steps:'
        'Review AGENTS.md and CONTRIBUTING.md'
        'Invoke-NovaTest'
        'Test-NovaBuild'
    )
}
