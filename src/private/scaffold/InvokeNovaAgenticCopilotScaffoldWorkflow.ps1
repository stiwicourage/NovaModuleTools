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
        [Parameter(Mandatory)][string]$Message
    )

    $choices = [System.Management.Automation.Host.ChoiceDescription[]]@(
        [System.Management.Automation.Host.ChoiceDescription]::new('&Yes', 'Apply the scaffold.'),
        [System.Management.Automation.Host.ChoiceDescription]::new('&No', 'Cancel the operation.')
    )

    return $Host.UI.PromptForChoice('Confirm', $Message, $choices, 1)
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

    Stop-NovaOperation -Message 'Operation cancelled.' -ErrorId 'Nova.Workflow.AgenticCopilotScaffoldCancelled' -Category OperationStopped -TargetObject $WorkflowContext.ProjectRoot
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

    Confirm-NovaAgenticCopilotScaffoldWarning -WorkflowContext $WorkflowContext
    Initialize-NovaModuleAgenticCopilotScaffold -Answer $WorkflowContext.AnswerSet -ProjectRoot $WorkflowContext.ProjectRoot -ScaffoldPolicy $WorkflowContext.ScaffoldPolicy
    Write-Message "Agentic Copilot scaffold applied to $( $WorkflowContext.ProjectInfo.ProjectName )" -color Green
}
