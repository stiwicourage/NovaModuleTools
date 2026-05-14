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

Describe 'Read-NovaModuleAnswerSet' {
    It 'asks for the project short name immediately after an affirmative Agentic selection' {
        InModuleScope $script:moduleName {
            $questions = Get-NovaModuleQuestionSet
            $askedCaptions = [System.Collections.Generic.List[string]]::new()
            Mock Read-AwesomeHost {
                $askedCaptions.Add($Ask.Caption)

                switch ($Ask.Caption) {
                    'Module Name' {
                        'NovaSample'
                    }
                    'Module Description' {
                        'Sample module'
                    }
                    'Semantic Version' {
                        '1.2.3'
                    }
                    'Module Author' {
                        'Tester'
                    }
                    'Supported PowerShell Version' {
                        '7.4'
                    }
                    'Git Version Control' {
                        'No'
                    }
                    'Agentic Copilot setup' {
                        'Yes'
                    }
                    'Project short name' {
                        'Nova'
                    }
                    'Pester Testing' {
                        'No'
                    }
                    default {
                        throw "Unexpected prompt: $( $Ask.Caption )"
                    }
                }
            }

            $answers = Read-NovaModuleAnswerSet -Questions $questions

            $answers.ProjectShortName | Should -Be 'Nova'
            $askedCaptions | Should -Be @(
                'Module Name',
                'Module Description',
                'Semantic Version',
                'Module Author',
                'Supported PowerShell Version',
                'Git Version Control',
                'Agentic Copilot setup',
                'Project short name',
                'Pester Testing'
            )
        }
    }

    It 'skips the project short name when Agentic Copilot setup is not selected' {
        InModuleScope $script:moduleName {
            $questions = Get-NovaModuleQuestionSet
            $askedCaptions = [System.Collections.Generic.List[string]]::new()
            Mock Read-AwesomeHost {
                $askedCaptions.Add($Ask.Caption)

                switch ($Ask.Caption) {
                    'Module Name' {
                        'NovaSample'
                    }
                    'Agentic Copilot setup' {
                        'No'
                    }
                    default {
                        'value'
                    }
                }
            }

            $answers = Read-NovaModuleAnswerSet -Questions $questions

            $answers.Keys | Should -Not -Contain 'ProjectShortName'
            $askedCaptions | Should -Not -Contain 'Project short name'
        }
    }
}
