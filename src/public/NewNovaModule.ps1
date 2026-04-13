function New-NovaModule {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [string]$Path = (Get-Location).Path
    )

    if (-not (Test-Path $Path)) {
        throw 'Not a valid path'
    }

    $questionSet = Get-NovaModuleQuestionSet
    $answerSet = Read-NovaModuleAnswerSet -Questions $questionSet
    $layout = Get-NovaModuleScaffoldLayout -Path $Path -ProjectName $answerSet.ProjectName

    if (-not $PSCmdlet.ShouldProcess($layout.Project, 'Create Nova module scaffold')) {
        return
    }

    Initialize-NovaModuleScaffold -Answer $answerSet -Paths $layout
    Write-NovaModuleProjectJson -Answer $answerSet -ProjectJsonFile $layout.ProjectJsonFile

    'Module {0} scaffolding complete' -f $answerSet.ProjectName | Write-Message -color Green
}
