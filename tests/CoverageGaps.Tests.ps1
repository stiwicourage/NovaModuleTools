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

            $thrown = $null
            try {
                Read-NovaModuleAnswerSet -Questions $questions
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be 'Module name is invalid. Use a single word that starts with a letter and contains only letters, numbers, underscores, or periods.'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Validation.ScaffoldProjectNameInvalid'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidData)
            $thrown.TargetObject | Should -Be 'bad name'
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

            $thrown = $null
            try {
                Initialize-NovaModuleScaffold -Answer @{EnablePester = 'No'; EnableGit = 'No'} -Paths $paths
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be 'Project already exists, aborting'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Workflow.ScaffoldProjectAlreadyExists'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::ResourceExists)
            $thrown.TargetObject | Should -Be $paths.Project

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
            $project.Package.OutputDirectory.Path | Should -Be 'artifacts/packages'
            $project.Package.OutputDirectory.Clean | Should -BeTrue
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
            $project.Package.OutputDirectory.Path | Should -Be 'artifacts/packages'
            $project.Package.Repositories[0].Headers.'X-Repository' | Should -Be 'example-raw'
            $project.Package.Repositories[0].Auth.TokenEnvironmentVariable | Should -Be 'NOVA_EXAMPLE_PACKAGE_TOKEN'
            $project.ContainsKey('Pester') | Should -BeTrue
        }
    }

    It 'Write-NovaModuleProjectJson delegates final persistence to Write-ProjectJsonData' {
        InModuleScope $script:moduleName {
            Mock Get-NovaModuleProjectTemplatePath {'/tmp/project-template.json'}
            Mock Read-ProjectJsonData {
                [ordered]@{
                    ProjectName = ''
                    Description = ''
                    Version = ''
                    Manifest = [ordered]@{
                        Author = ''
                        PowerShellHostVersion = ''
                        GUID = ''
                    }
                    Package = [ordered]@{
                        OutputDirectory = [ordered]@{
                            Path = 'artifacts/packages'
                            Clean = $true
                        }
                    }
                    Pester = [ordered]@{
                        TestResult = [ordered]@{
                            Enabled = $true
                        }
                    }
                }
            }
            Mock New-Guid {[guid]'22222222-2222-2222-2222-222222222222'}
            Mock Write-ProjectJsonData {}

            Write-NovaModuleProjectJson -Answer @{
                ProjectName = 'NovaDelegated'
                Description = 'Shared writer path'
                Version = '3.2.1'
                Author = 'Writer Test'
                PowerShellHostVersion = '7.4'
                EnablePester = 'Yes'
            } -ProjectJsonFile '/tmp/project.json'

            Assert-MockCalled Read-ProjectJsonData -Times 1 -ParameterFilter {$ProjectJsonPath -eq '/tmp/project-template.json'}
            Assert-MockCalled Write-ProjectJsonData -Times 1 -ParameterFilter {
                $ProjectJsonPath -eq '/tmp/project.json' -and
                        $Data.ProjectName -eq 'NovaDelegated' -and
                        $Data.Manifest.GUID -eq '22222222-2222-2222-2222-222222222222' -and
                        $Data.Package.OutputDirectory.Path -eq 'artifacts/packages'
            }
        }
    }

    It 'Initialize-NovaModule creates a scaffolded project when confirmed' {
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

            Initialize-NovaModule -Path $TestDrive -Confirm:$false

            $projectRoot = Join-Path $TestDrive 'NovaScaffold'
            Test-Path -LiteralPath (Join-Path $projectRoot 'project.json') | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $projectRoot 'src/public') | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $projectRoot 'tests') | Should -BeTrue
        }
    }

    It 'Get-NovaModuleInitializationWorkflowContext resolves scaffold inputs and ShouldProcess metadata' {
        InModuleScope $script:moduleName {
            Mock Resolve-NovaModuleScaffoldBasePath {'/tmp/base'}
            Mock Get-NovaModuleQuestionSet {[ordered]@{ProjectName = @{Prompt = 'Name?'}}}
            Mock Read-NovaModuleAnswerSet {
                [ordered]@{
                    ProjectName = 'NovaContext'
                    EnableGit = 'No'
                }
            }
            Mock Get-NovaModuleScaffoldLayout {
                [pscustomobject]@{
                    Project = '/tmp/base/NovaContext'
                    ProjectJsonFile = '/tmp/base/NovaContext/project.json'
                }
            }

            $result = Get-NovaModuleInitializationWorkflowContext -Path '/tmp/base' -Example

            $result.BasePath | Should -Be '/tmp/base'
            $result.AnswerSet.ProjectName | Should -Be 'NovaContext'
            $result.Layout.Project | Should -Be '/tmp/base/NovaContext'
            $result.Example | Should -BeTrue
            $result.Target | Should -Be '/tmp/base/NovaContext'
            $result.Action | Should -Be 'Create Nova module scaffold'
            Assert-MockCalled Get-NovaModuleQuestionSet -Times 1 -ParameterFilter {$Example}
            Assert-MockCalled Get-NovaModuleScaffoldLayout -Times 1 -ParameterFilter {
                $Path -eq '/tmp/base' -and $ProjectName -eq 'NovaContext'
            }
        }
    }

    It 'Invoke-NovaModuleInitializationWorkflow runs scaffold creation, project.json writing, and completion messaging' {
        InModuleScope $script:moduleName {
            $workflowContext = [pscustomobject]@{
                AnswerSet = [ordered]@{ProjectName = 'NovaWorkflow'}
                Layout = [pscustomobject]@{
                    Project = '/tmp/base/NovaWorkflow'
                    ProjectJsonFile = '/tmp/base/NovaWorkflow/project.json'
                }
                Example = $true
            }
            Mock Initialize-NovaModuleScaffold {}
            Mock Write-NovaModuleProjectJson {}
            Mock Write-Message {}

            Invoke-NovaModuleInitializationWorkflow -WorkflowContext $workflowContext

            Assert-MockCalled Initialize-NovaModuleScaffold -Times 1 -ParameterFilter {
                $Answer.ProjectName -eq 'NovaWorkflow' -and
                        $Paths.Project -eq '/tmp/base/NovaWorkflow' -and
                        $Example
            }
            Assert-MockCalled Write-NovaModuleProjectJson -Times 1 -ParameterFilter {
                $Answer.ProjectName -eq 'NovaWorkflow' -and
                        $ProjectJsonFile -eq '/tmp/base/NovaWorkflow/project.json' -and
                        $Example
            }
            Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
                $Text -eq 'Module NovaWorkflow scaffolding complete' -and $color -eq 'Green'
            }
        }
    }

    It 'Initialize-NovaModule delegates workflow context resolution and execution to private helpers' {
        InModuleScope $script:moduleName {
            Mock Get-NovaModuleInitializationWorkflowContext {
                [pscustomobject]@{
                    Target = '/tmp/base/NovaDelegation'
                    Action = 'Create Nova module scaffold'
                    AnswerSet = [ordered]@{ProjectName = 'NovaDelegation'}
                    Layout = [pscustomobject]@{Project = '/tmp/base/NovaDelegation'}
                    Example = $false
                }
            }
            Mock Invoke-NovaModuleInitializationWorkflow {}

            Initialize-NovaModule -Path '/tmp/base' -Confirm:$false

            Assert-MockCalled Get-NovaModuleInitializationWorkflowContext -Times 1 -ParameterFilter {
                $Path -eq '/tmp/base' -and -not $Example
            }
            Assert-MockCalled Invoke-NovaModuleInitializationWorkflow -Times 1 -ParameterFilter {
                $WorkflowContext.Target -eq '/tmp/base/NovaDelegation' -and
                        $WorkflowContext.Action -eq 'Create Nova module scaffold'
            }
        }
    }

    It 'Initialize-NovaModule defaults Path to the current location when Path is omitted' {
        InModuleScope $script:moduleName {
            Mock Get-Location {[pscustomobject]@{Path = '/tmp/default-scaffold-root'}}
            Mock Get-NovaModuleInitializationWorkflowContext {
                [pscustomobject]@{
                    Target = '/tmp/default-scaffold-root/NovaDelegation'
                    Action = 'Create Nova module scaffold'
                }
            }
            Mock Invoke-NovaModuleInitializationWorkflow {}

            Initialize-NovaModule -Confirm:$false

            Assert-MockCalled Get-NovaModuleInitializationWorkflowContext -Times 1 -ParameterFilter {
                $Path -eq '/tmp/default-scaffold-root' -and -not $Example
            }
            Assert-MockCalled Invoke-NovaModuleInitializationWorkflow -Times 1 -ParameterFilter {
                $WorkflowContext.Target -eq '/tmp/default-scaffold-root/NovaDelegation'
            }
        }
    }

    It 'Initialize-NovaModule -Example creates the packaged example scaffold without asking about Pester' {
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

            Initialize-NovaModule -Path $TestDrive -Example -Confirm:$false

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

    It 'Initialize-NovaModule reports invalid paths and skips initialization on WhatIf' {
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

            $thrown = $null
            try {
                Initialize-NovaModule -Path '/tmp/does-not-exist' -WhatIf
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be 'Not a valid path: /tmp/does-not-exist'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Environment.ScaffoldBasePathNotFound'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::ObjectNotFound)
            $thrown.TargetObject | Should -Be '/tmp/does-not-exist'

            Assert-MockCalled Initialize-NovaModuleScaffold -Times 0
            Assert-MockCalled Write-NovaModuleProjectJson -Times 0
        }
    }

    It 'Read-NovaModuleAnswerSet rejects invalid module names with a terminating error' {
        InModuleScope $script:moduleName {
            Mock Read-AwesomeHost {'invalid name!'}

            $thrown = $null
            try {
                Read-NovaModuleAnswerSet -Questions @{ProjectName = @{Prompt = 'Name?'}}
            }
            catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be 'Module name is invalid. Use a single word that starts with a letter and contains only letters, numbers, underscores, or periods.'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Validation.ScaffoldProjectNameInvalid'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidData)
            $thrown.TargetObject | Should -Be 'invalid name!'
        }
    }
}
