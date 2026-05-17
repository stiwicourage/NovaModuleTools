BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Get-NovaModuleQuestionSet' {
    It 'includes the conditional project short name prompt in the standard scaffold flow' {
        InModuleScope $script:moduleName {
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
    }

    It 'keeps the project short name prompt in the example scaffold flow without the Pester question' {
        InModuleScope $script:moduleName {
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
}
