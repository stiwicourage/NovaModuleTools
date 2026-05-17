BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/GetNovaModuleQuestions.ps1')
}

Describe 'Get-NovaModuleQuestionSet' {
    It 'includes the conditional project short name prompt in the standard scaffold flow' {
        $questions = Get-NovaModuleQuestionSet

        $questions.Keys | Should -Be @(
            'ProjectName',
            'Description',
            'Version',
            'Author',
            'PowerShellHostVersion',
            'EnableGit',
            'EnableAgenticCopilot',
            'ProjectShortName',
            'EnablePester'
        )
        $questions.ProjectShortName.Caption | Should -Be 'Project short name'
        $questions.ProjectShortName.Message | Should -Match 'NovaModuleTools the short name is Nova'
        $questions.ProjectShortName.Message | Should -Match 'NMT'
        (& $questions.ProjectShortName.Condition ([ordered]@{EnableAgenticCopilot = 'Yes'})) | Should -BeTrue
        (& $questions.ProjectShortName.Condition ([ordered]@{EnableAgenticCopilot = 'No'})) | Should -BeFalse
        (& $questions.ProjectShortName.Validation.Test 'Nova') | Should -BeTrue
        (& $questions.ProjectShortName.Validation.Test 'bad name') | Should -BeFalse
    }

    It 'keeps the project short name prompt in the example scaffold flow without the Pester question' {
        $questions = Get-NovaModuleQuestionSet -Example

        $questions.Keys | Should -Be @(
            'ProjectName',
            'Description',
            'Version',
            'Author',
            'PowerShellHostVersion',
            'EnableGit',
            'EnableAgenticCopilot',
            'ProjectShortName'
        )
        $questions.Contains('EnablePester') | Should -BeFalse
    }
}
