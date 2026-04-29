function Get-NovaModuleInitializationWorkflowContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$Example
    )

    $basePath = Resolve-NovaModuleScaffoldBasePath -Path $Path
    $questionSet = Get-NovaModuleQuestionSet -Example:$Example
    $answerSet = Read-NovaModuleAnswerSet -Questions $questionSet
    $layout = Get-NovaModuleScaffoldLayout -Path $basePath -ProjectName $answerSet.ProjectName

    return [pscustomobject]@{
        BasePath = $basePath
        QuestionSet = $questionSet
        AnswerSet = $answerSet
        Layout = $layout
        Example = $Example.IsPresent
        Target = $layout.Project
        Action = 'Create Nova module scaffold'
    }
}
