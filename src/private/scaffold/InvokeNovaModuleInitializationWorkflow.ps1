function Invoke-NovaModuleInitializationWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    Initialize-NovaModuleScaffold -Answer $WorkflowContext.AnswerSet -Paths $WorkflowContext.Layout -Example:$WorkflowContext.Example
    Write-NovaModuleProjectJson -Answer $WorkflowContext.AnswerSet -ProjectJsonFile $WorkflowContext.Layout.ProjectJsonFile -Example:$WorkflowContext.Example
    if ($WorkflowContext.AnswerSet.EnableAgenticCopilot -eq 'Yes') {
        Initialize-NovaModuleAgenticCopilotScaffold -Answer $WorkflowContext.AnswerSet -ProjectRoot $WorkflowContext.Layout.Project -Example:$WorkflowContext.Example
    }

    'Module {0} scaffolding complete' -f $WorkflowContext.AnswerSet.ProjectName | Write-Message -color Green
}
