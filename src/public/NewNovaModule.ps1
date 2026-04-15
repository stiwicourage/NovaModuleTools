function New-NovaModule {
    [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
    param (
        [string]$Path = (Get-Location).Path,
        [switch]$Example
    )

    $basePath = Resolve-NovaModuleScaffoldBasePath -Path $Path
    $questionSet = Get-NovaModuleQuestionSet -Example:$Example
    $answerSet = Read-NovaModuleAnswerSet -Questions $questionSet
    $layout = Get-NovaModuleScaffoldLayout -Path $basePath -ProjectName $answerSet.ProjectName

    if (-not $PSCmdlet.ShouldProcess($layout.Project, 'Create Nova module scaffold')) {
        return
    }

    Initialize-NovaModuleScaffold -Answer $answerSet -Paths $layout -Example:$Example
    Write-NovaModuleProjectJson -Answer $answerSet -ProjectJsonFile $layout.ProjectJsonFile -Example:$Example

    'Module {0} scaffolding complete' -f $answerSet.ProjectName | Write-Message -color Green
}
