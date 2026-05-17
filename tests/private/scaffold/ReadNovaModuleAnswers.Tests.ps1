BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/GetNovaModuleQuestions.ps1')
    . (Join-Path $projectRoot 'src/private/scaffold/ReadNovaModuleAnswers.ps1')

    . (Join-Path $PSScriptRoot 'ReadNovaModuleAnswers.TestSupport.ps1')
}

Describe 'Read-NovaModuleAnswerSet' {
    It 'asks for the project short name immediately after an affirmative Agentic selection' {
        $questions = Get-NovaModuleQuestionSet
        $script:askedCaptions = [System.Collections.Generic.List[string]]::new()
        Mock Read-AwesomeHost {
            $script:askedCaptions.Add($Ask.Caption)
            switch ($Ask.Caption) {
                'Module Name' {'NovaSample'}
                'Module Description' {'Sample module'}
                'Semantic Version' {'1.2.3'}
                'Module Author' {'Tester'}
                'Supported PowerShell Version' {'7.4'}
                'Git Version Control' {'No'}
                'Agentic Copilot setup' {'Yes'}
                'Project short name' {'Nova'}
                'Pester Testing' {'No'}
                default {throw "Unexpected prompt: $($Ask.Caption)"}
            }
        }

        $answers = Read-NovaModuleAnswerSet -Questions $questions

        $answers.ProjectShortName | Should -Be 'Nova'
        $script:askedCaptions | Should -Be @(
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

    It 'skips the project short name when Agentic Copilot setup is not selected' {
        $questions = Get-NovaModuleQuestionSet
        $script:askedCaptions = [System.Collections.Generic.List[string]]::new()
        Mock Read-AwesomeHost {
            $script:askedCaptions.Add($Ask.Caption)
            switch ($Ask.Caption) {
                'Module Name' {'NovaSample'}
                'Agentic Copilot setup' {'No'}
                default {'value'}
            }
        }

        $answers = Read-NovaModuleAnswerSet -Questions $questions

        $answers.Keys | Should -Not -Contain 'ProjectShortName'
        $script:askedCaptions | Should -Not -Contain 'Project short name'
    }
}
