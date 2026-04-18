$script:gitTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'GitTestSupport.ps1')).Path
$global:gitTestSupportFunctionNameList = @(
    'Initialize-TestGitRepository'
    'New-TestGitCommit'
    'New-TestGitTag'
)
. $script:gitTestSupportPath

foreach ($functionName in $global:gitTestSupportFunctionNameList) {
    $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
    Set-Item -Path "function:global:$functionName" -Value $scriptBlock
}

BeforeAll {
    $here = Split-Path -Parent $PSCommandPath
    $gitTestSupportPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'GitTestSupport.ps1')).Path
    $script:repoRoot = Split-Path -Parent $here
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    . $gitTestSupportPath
    foreach ($functionName in $global:gitTestSupportFunctionNameList) {
        $scriptBlock = (Get-Command -Name $functionName -CommandType Function -ErrorAction Stop).ScriptBlock
        Set-Item -Path "function:global:$functionName" -Value $scriptBlock
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Coverage gaps for scaffold internals' {
    It 'Get-NovaModuleQuestionSet returns the expected scaffold questions' {
        InModuleScope $script:moduleName {
            $questions = Get-NovaModuleQuestionSet

            $questions.Keys | Should -Be @(
                'ProjectName',
                'Description',
                'Version',
                'Author',
                'PowerShellHostVersion',
                'EnableGit',
                'EnablePester'
            )
            $questions.ProjectName.Default | Should -Be 'MANDATORY'
            $questions.EnableGit.Choice.Yes | Should -Be 'Enable Git'
            $questions.EnablePester.Choice.No | Should -Be 'Skip pester testing'
        }
    }

    It 'Get-NovaModuleQuestionSet omits the Pester prompt for the example flow' {
        InModuleScope $script:moduleName {
            $questions = Get-NovaModuleQuestionSet -Example

            $questions.Keys | Should -Be @(
                'ProjectName',
                'Description',
                'Version',
                'Author',
                'PowerShellHostVersion',
                'EnableGit'
            )
            $questions.Contains('EnablePester') | Should -BeFalse
        }
    }

    It 'Get-NovaModuleScaffoldLayout returns the expected scaffold paths' {
        InModuleScope $script:moduleName {
            $layout = Get-NovaModuleScaffoldLayout -Path '/tmp/root' -ProjectName 'NovaSample'

            $layout.Project | Should -Be '/tmp/root/NovaSample'
            $layout.Src | Should -Be '/tmp/root/NovaSample/src'
            $layout.Private | Should -Be '/tmp/root/NovaSample/src/private'
            $layout.Public | Should -Be '/tmp/root/NovaSample/src/public'
            $layout.Resources | Should -Be '/tmp/root/NovaSample/src/resources'
            $layout.Classes | Should -Be '/tmp/root/NovaSample/src/classes'
            $layout.Tests | Should -Be '/tmp/root/NovaSample/tests'
            $layout.ProjectJsonFile | Should -Be '/tmp/root/NovaSample/project.json'
        }
    }

    It 'Resolve-NovaModuleScaffoldBasePath normalizes slash styles to the current platform' {
        InModuleScope $script:moduleName {
            $root = Join-Path $TestDrive 'scaffold-root'
            $nested = Join-Path $root 'nested/child'
            $null = New-Item -ItemType Directory -Path $nested -Force
            $mixedStylePath = if ([System.IO.Path]::DirectorySeparatorChar -eq '/') {
                $nested.Replace('/', '\')
            }
            else {
                $nested.Replace('\', '/')
            }

            $resolved = Resolve-NovaModuleScaffoldBasePath -Path $mixedStylePath

            $resolved | Should -Be ([System.IO.Path]::GetFullPath($nested))
        }
    }

    It 'Read-NovaModuleAnswerSet reads answers for every scaffold question' {
        InModuleScope $script:moduleName {
            $questions = Get-NovaModuleQuestionSet
            Mock Read-AwesomeHost {
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
                    'Pester Testing' {
                        'Yes'
                    }
                    default {
                        throw "Unexpected prompt: $( $Ask.Caption )"
                    }
                }
            }

            $answers = Read-NovaModuleAnswerSet -Questions $questions

            $answers.ProjectName | Should -Be 'NovaSample'
            $answers.Description | Should -Be 'Sample module'
            $answers.Version | Should -Be '1.2.3'
            $answers.Author | Should -Be 'Tester'
            $answers.PowerShellHostVersion | Should -Be '7.4'
            $answers.EnableGit | Should -Be 'No'
            $answers.EnablePester | Should -Be 'Yes'
            Assert-MockCalled Read-AwesomeHost -Times $questions.Count
        }
    }

    It 'Read-NovaModuleAnswerSet preserves the scaffold question order' {
        InModuleScope $script:moduleName {
            $questions = Get-NovaModuleQuestionSet
            $askedCaptions = [System.Collections.Generic.List[string]]::new()
            Mock Read-AwesomeHost {
                $askedCaptions.Add($Ask.Caption)

                if ($Ask.Caption -eq 'Module Name') {
                    return 'NovaSample'
                }

                return 'value'
            }

            $null = Read-NovaModuleAnswerSet -Questions $questions

            $askedCaptions | Should -Be @(
                'Module Name',
                'Module Description',
                'Semantic Version',
                'Module Author',
                'Supported PowerShell Version',
                'Git Version Control',
                'Pester Testing'
            )
        }
    }

    It 'Read-NovaModuleAnswerSet rejects invalid project names' {
        InModuleScope $script:moduleName {
            $questions = Get-NovaModuleQuestionSet
            Mock Read-AwesomeHost {
                switch ($Ask.Caption) {
                    'Module Name' {
                        'bad name'
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
                    'Pester Testing' {
                        'No'
                    }
                    default {
                        throw "Unexpected prompt: $( $Ask.Caption )"
                    }
                }
            }
            {Read-NovaModuleAnswerSet -Questions $questions} | Should -Throw 'Module name is invalid*'
        }
    }

    It 'Initialize-NovaModuleScaffold creates directories and optional integrations' {
        InModuleScope $script:moduleName {
            $paths = Get-NovaModuleScaffoldLayout -Path $TestDrive -ProjectName 'Scaffolded'
            $answer = @{
                EnablePester = 'Yes'
                EnableGit = 'Yes'
            }
            Mock Write-Message {}
            Mock New-InitiateGitRepo {}

            Initialize-NovaModuleScaffold -Answer $answer -Paths $paths

            foreach ($directory in @($paths.Project, $paths.Src, $paths.Private, $paths.Public, $paths.Resources, $paths.Classes, $paths.Tests)) {
                Test-Path -LiteralPath $directory | Should -BeTrue
            }
            Assert-MockCalled New-InitiateGitRepo -Times 1 -ParameterFilter {$DirectoryPath -eq $paths.Project}
        }
    }

    It 'Initialize-NovaModuleScaffold copies the example template and keeps tests in place' {
        InModuleScope $script:moduleName {
            $paths = Get-NovaModuleScaffoldLayout -Path $TestDrive -ProjectName 'ExampleScaffold'
            Mock Write-Message {}
            Mock New-InitiateGitRepo {}

            Initialize-NovaModuleScaffold -Answer @{EnableGit = 'No'} -Paths $paths -Example

            (Test-Path -LiteralPath (Join-Path $paths.Project 'README.md')) | Should -BeTrue
            (Test-Path -LiteralPath $paths.Tests) | Should -BeTrue
            (Test-Path -LiteralPath (Join-Path $paths.Public 'Get-ExampleGreeting.ps1')) | Should -BeTrue
        }
    }

    It 'Initialize-NovaModuleScaffold reports an existing project path' {
        InModuleScope $script:moduleName {
            $paths = [pscustomobject]@{
                Project = Join-Path $TestDrive 'ExistingProject'
                Src = Join-Path $TestDrive 'ExistingProject/src'
                Private = Join-Path $TestDrive 'ExistingProject/src/private'
                Public = Join-Path $TestDrive 'ExistingProject/src/public'
                Resources = Join-Path $TestDrive 'ExistingProject/src/resources'
                Classes = Join-Path $TestDrive 'ExistingProject/src/classes'
                Tests = Join-Path $TestDrive 'ExistingProject/tests'
            }
            $null = New-Item -ItemType Directory -Path $paths.Project -Force
            Mock Write-Message {}
            Mock New-Item {}
            Mock New-InitiateGitRepo {}

            {
                Initialize-NovaModuleScaffold -Answer @{EnablePester = 'No'; EnableGit = 'No'} -Paths $paths
            } | Should -Throw 'Project already exists, aborting'

            Assert-MockCalled New-Item -Times 0
            Assert-MockCalled New-InitiateGitRepo -Times 0
        }
    }

    It 'Write-NovaModuleProjectJson writes project metadata and can omit the Pester section' {
        InModuleScope $script:moduleName {
            $projectJsonPath = Join-Path $TestDrive 'project.json'
            Mock New-Guid {[guid]'11111111-1111-1111-1111-111111111111'}

            Write-NovaModuleProjectJson -Answer @{
                ProjectName = 'NovaJson'
                Description = 'Generated project'
                Version = '2.3.4'
                Author = 'Test Author'
                PowerShellHostVersion = '7.4'
                EnablePester = 'No'
            } -ProjectJsonFile $projectJsonPath

            $project = Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json -AsHashtable
            $project.ProjectName | Should -Be 'NovaJson'
            $project.Description | Should -Be 'Generated project'
            $project.Version | Should -Be '2.3.4'
            $project.ContainsKey('CopyResourcesToModuleRoot') | Should -BeFalse
            $project.Manifest.Author | Should -Be 'Test Author'
            $project.Manifest.PowerShellHostVersion | Should -Be '7.4'
            $project.Manifest.GUID | Should -Be '11111111-1111-1111-1111-111111111111'
            $project.ContainsKey('Pester') | Should -BeFalse
        }
    }

    It 'Write-NovaModuleProjectJson preserves example-only settings while applying prompt values' {
        InModuleScope $script:moduleName {
            $projectJsonPath = Join-Path $TestDrive 'example-project.json'

            Write-NovaModuleProjectJson -Answer @{
                ProjectName = 'CustomExample'
                Description = 'Customized example project'
                Version = '9.8.7'
                Author = 'Example Author'
                PowerShellHostVersion = '7.5'
            } -ProjectJsonFile $projectJsonPath -Example

            $project = Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json -AsHashtable
            $project.ProjectName | Should -Be 'CustomExample'
            $project.Description | Should -Be 'Customized example project'
            $project.Version | Should -Be '9.8.7'
            $project.CopyResourcesToModuleRoot | Should -BeFalse
            $project.BuildRecursiveFolders | Should -BeTrue
            $project.Manifest.Author | Should -Be 'Example Author'
            $project.Manifest.PowerShellHostVersion | Should -Be '7.5'
            $project.Manifest.GUID | Should -Be 'b3b4ca64-a274-4768-872d-2b3c8bc12a39'
            $project.ContainsKey('Pester') | Should -BeTrue
        }
    }

    It 'New-NovaModule creates a scaffolded project when confirmed' {
        InModuleScope $script:moduleName {
            $answer = @{
                ProjectName = 'NovaScaffold'
                Description = 'Scaffolded module'
                Version = '1.0.0'
                Author = 'Tester'
                PowerShellHostVersion = '7.4'
                EnableGit = 'No'
                EnablePester = 'Yes'
            }
            Mock Read-NovaModuleAnswerSet {$answer}
            Mock Write-Message {}
            Mock New-InitiateGitRepo {}

            New-NovaModule -Path $TestDrive -Confirm:$false

            $projectRoot = Join-Path $TestDrive 'NovaScaffold'
            Test-Path -LiteralPath (Join-Path $projectRoot 'project.json') | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $projectRoot 'src/public') | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $projectRoot 'tests') | Should -BeTrue
        }
    }

    It 'New-NovaModule -Example creates the packaged example scaffold without asking about Pester' {
        InModuleScope $script:moduleName {
            $answer = @{
                ProjectName = 'NovaExampleScaffold'
                Description = 'Scaffolded from example'
                Version = '1.0.0'
                Author = 'Tester'
                PowerShellHostVersion = '7.4'
                EnableGit = 'No'
            }
            Mock Read-NovaModuleAnswerSet {$answer}
            Mock Write-Message {}
            Mock New-InitiateGitRepo {}

            New-NovaModule -Path $TestDrive -Example -Confirm:$false

            $projectRoot = Join-Path $TestDrive 'NovaExampleScaffold'
            $project = Get-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Raw | ConvertFrom-Json -AsHashtable

            Test-Path -LiteralPath (Join-Path $projectRoot 'tests') | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $projectRoot 'src/public/Get-ExampleGreeting.ps1') | Should -BeTrue
            $project.ProjectName | Should -Be 'NovaExampleScaffold'
            $project.Description | Should -Be 'Scaffolded from example'
            $project.Manifest.Author | Should -Be 'Tester'
            $project.ContainsKey('Pester') | Should -BeTrue
            $project.Manifest.GUID | Should -Be 'b3b4ca64-a274-4768-872d-2b3c8bc12a39'

            Assert-MockCalled Read-NovaModuleAnswerSet -Times 1
            Assert-MockCalled Read-NovaModuleAnswerSet -ParameterFilter {
                -not $Questions.Contains('EnablePester')
            }
        }
    }

    It 'New-NovaModule reports invalid paths and skips initialization on WhatIf' {
        InModuleScope $script:moduleName {
            Mock Test-Path {$false}
            Mock Get-NovaModuleQuestionSet {@{ProjectName = @{}}}
            Mock Read-NovaModuleAnswerSet {@{ProjectName = 'NovaDryRun'}}
            Mock Get-NovaModuleScaffoldLayout {
                [pscustomobject]@{
                    Project = '/tmp/NovaDryRun'
                    ProjectJsonFile = '/tmp/NovaDryRun/project.json'
                }
            }
            Mock Initialize-NovaModuleScaffold {}
            Mock Write-NovaModuleProjectJson {}

            {New-NovaModule -Path '/tmp/does-not-exist' -WhatIf} | Should -Throw 'Not a valid path*'

            Assert-MockCalled Initialize-NovaModuleScaffold -Times 0
            Assert-MockCalled Write-NovaModuleProjectJson -Times 0
        }
    }

    It 'Read-NovaModuleAnswerSet rejects invalid module names with a terminating error' {
        InModuleScope $script:moduleName {
            Mock Read-AwesomeHost {'invalid name!'}

            {
                Read-NovaModuleAnswerSet -Questions @{ProjectName = @{Prompt = 'Name?'}}
            } | Should -Throw 'Module name is invalid*'
        }
    }
}
