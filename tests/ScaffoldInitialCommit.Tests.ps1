BeforeAll {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    . (Join-Path $PSScriptRoot 'ScaffoldInitialCommit.TestSupport.ps1')
    foreach ($relativePath in @(
        'scaffold/InvokeNovaModuleInitializationWorkflow.ps1',
        'scaffold/InitializeNovaModuleScaffold.ps1',
        'scaffold/GetNovaModuleScaffoldPaths.ps1',
        'scaffold/UpdateNovaGitIgnore.ps1',
        'release/InitiateGitRepo.ps1',
        'shared/InvokeNovaGitCommand.ps1',
        'scaffold/CompleteScaffoldGitRepository.ps1',
        'scaffold/GetNovaModuleProjectTemplatePath.ps1',
        'scaffold/GetNovaModuleAgenticCopilotTemplateRoot.ps1'
    )) {
        . (Join-Path $projectRoot "src/private/$relativePath")
    }
    function Stop-NovaOperation { param($Message, $ErrorId, $Category, $TargetObject) throw $Message }
    function Write-Message { param($InputObject, $color) }
    function Write-NovaModuleProjectJson { param($Answer, $ProjectJsonFile, [switch]$Example) }
    function Write-NovaVsCodeSettings { param($ProjectRoot) }
    function Initialize-NovaModuleAgenticCopilotScaffold { param($Answer, $ProjectRoot, [switch]$Example) }
    function Copy-NovaExampleProjectTemplate { param($DestinationPath) }
    Get-Command git -ErrorAction Stop | Out-Null
}

# This exercises the file-generation workflow and real Git together; isolated mocks cannot prove HEAD or index safety.
Describe 'Nova Init initial commit' -Tag 'NovaInitGit' {
    BeforeEach {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $null = New-Item -ItemType Directory -Path $root
        $savedEnvironment = Set-ScaffoldTestGitEnvironment -Root $root
        $context = New-ScaffoldCommitTestContext -Root $root
        Mock Write-Message {}
        Mock Write-NovaModuleProjectJson {
            param($Answer, $ProjectJsonFile)
            Set-Content -LiteralPath $ProjectJsonFile -Value '{"ProjectName":"DemoModule"}'
        }
        Mock Write-NovaVsCodeSettings {
            param($ProjectRoot)
            $null = New-Item -ItemType Directory -Path (Join-Path $ProjectRoot '.vscode') -Force
            Set-Content -LiteralPath (Join-Path $ProjectRoot '.vscode/settings.json') -Value '{}'
        }
    }

    AfterEach {
        Restore-ScaffoldTestGitEnvironment -Saved $savedEnvironment
    }

    It 'commits all generated files only after project.json and editor settings exist' {
        Invoke-NovaModuleInitializationWorkflow -WorkflowContext $context

        $head = Invoke-NovaGitCommand -ProjectRoot $context.Layout.Project -Arguments @('rev-parse', '--verify', 'HEAD')
        $head.ExitCode | Should -Be 0
        Invoke-ScaffoldTestGit -Root $context.Layout.Project -ArgumentList @('log', '-1', '--format=%s') | Should -Be 'chore: Initial commit'
        $files = Invoke-ScaffoldTestGit -Root $context.Layout.Project -ArgumentList @('ls-tree', '-r', '--name-only', 'HEAD')
        @($files | Sort-Object) | Should -Be @('.gitignore', '.vscode/settings.json', 'project.json')
        Invoke-ScaffoldTestGit -Root $context.Layout.Project -ArgumentList @('status', '--porcelain') | Should -BeNullOrEmpty
    }

    It 'bypasses a HEAD-requiring <HookSetup> hook once without disabling it' -TestCases @(
        @{ HookSetup = 'template' },
        @{ HookSetup = 'configured hooksPath' }
    ) {
        param($HookSetup)
        Write-ScaffoldHeadRequiringHook
        if ($HookSetup -eq 'configured hooksPath') {
            $null = Invoke-ScaffoldTestGit -Root $root -ArgumentList @('config', '--global', 'core.hooksPath', (Join-Path $env:GIT_TEMPLATE_DIR 'hooks'))
        }
        $originalConfig = Get-Content -LiteralPath $env:GIT_CONFIG_GLOBAL -Raw
        Invoke-NovaModuleInitializationWorkflow -WorkflowContext $context

        (Invoke-NovaGitCommand -ProjectRoot $context.Layout.Project -Arguments @('rev-parse', '--verify', 'HEAD')).ExitCode | Should -Be 0
        Test-Path -LiteralPath (Join-Path $context.Layout.Project '.git/hook-ran') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $context.Layout.Project '.git/hooks/pre-commit') | Should -BeTrue
        Add-Content -LiteralPath $context.Layout.ProjectJsonFile -Value ' '
        $null = Invoke-ScaffoldTestGit -Root $context.Layout.Project -ArgumentList @('add', '--', 'project.json')
        $null = Invoke-ScaffoldTestGit -Root $context.Layout.Project -ArgumentList @('commit', '-m', 'fixture: second commit')
        Test-Path -LiteralPath (Join-Path $context.Layout.Project '.git/hook-ran') | Should -BeTrue
        Get-Content -LiteralPath $env:GIT_CONFIG_GLOBAL -Raw | Should -BeExactly $originalConfig
    }

    It 'does not invoke Git when disabled' {
        $context.AnswerSet.EnableGit = 'No'
        Mock Invoke-NovaGitCommand { throw 'Git must not run.' }

        Invoke-NovaModuleInitializationWorkflow -WorkflowContext $context

        Test-Path -LiteralPath (Join-Path $context.Layout.Project '.git') | Should -BeFalse
        Test-Path -LiteralPath $context.Layout.ProjectJsonFile | Should -BeTrue
    }

    It 'does not stage an unrelated file added during project generation' {
        Mock Write-NovaVsCodeSettings {
            param($ProjectRoot)
            Set-Content -LiteralPath (Join-Path $ProjectRoot 'user-notes.txt') -Value 'User-owned'
        }

        Invoke-NovaModuleInitializationWorkflow -WorkflowContext $context

        (Invoke-NovaGitCommand -ProjectRoot $context.Layout.Project -Arguments @('rev-parse', '--verify', 'HEAD')).ExitCode | Should -Be 0
        $files = Invoke-ScaffoldTestGit -Root $context.Layout.Project -ArgumentList @('ls-tree', '-r', '--name-only', 'HEAD')
        $files | Should -Not -Contain 'user-notes.txt'
        Invoke-ScaffoldTestGit -Root $context.Layout.Project -ArgumentList @('status', '--porcelain') | Should -Be '?? user-notes.txt'
    }

    It 'commits the <Variant> template manifest using literal paths, not matching user filenames' -TestCases @(
        @{ Variant = 'example' },
        @{ Variant = 'Agentic Copilot' }
    ) {
        param($Variant)
        $templateRoot = Join-Path $root 'scaffold-template'
        $null = New-Item -ItemType Directory -Path $templateRoot
        Set-Content -LiteralPath (Join-Path $templateRoot 'project.json') -Value '{}'
        Set-Content -LiteralPath (Join-Path $templateRoot 'file [1].txt') -Value 'Generated'
        Set-Content -LiteralPath (Join-Path $templateRoot '.generated') -Value 'Generated hidden file'
        Mock Get-NovaModuleProjectTemplatePath { Join-Path $templateRoot 'project.json' }
        Mock Get-NovaModuleAgenticCopilotTemplateRoot { $templateRoot }
        Mock Copy-NovaExampleProjectTemplate {
            param($DestinationPath)
            Get-ChildItem -LiteralPath $templateRoot -Force | Copy-Item -Destination $DestinationPath
        }
        Mock Initialize-NovaModuleAgenticCopilotScaffold {
            param($ProjectRoot)
            Get-ChildItem -LiteralPath $templateRoot -Force | Copy-Item -Destination $ProjectRoot
        }
        Mock Write-NovaVsCodeSettings {
            param($ProjectRoot)
            Set-Content -LiteralPath (Join-Path $ProjectRoot 'file 1.txt') -Value 'User-owned'
        }
        $context.Example = $Variant -eq 'example'
        if (-not $context.Example) { $context.AnswerSet.EnableAgenticCopilot = 'Yes' }

        Invoke-NovaModuleInitializationWorkflow -WorkflowContext $context

        $files = Invoke-ScaffoldTestGit -Root $context.Layout.Project -ArgumentList @('ls-tree', '-r', '--name-only', 'HEAD')
        @($files | Sort-Object) | Should -Be @('.generated', '.gitignore', 'file [1].txt', 'project.json')
        Invoke-ScaffoldTestGit -Root $context.Layout.Project -ArgumentList @('status', '--porcelain') | Should -Be '?? "file 1.txt"'
    }

    It 'respects ignore rules for otherwise generated files' {
        $excludePath = Join-Path $root 'global-ignore'
        Set-Content -LiteralPath $excludePath -Value ".vscode/`nproject.json"
        $null = Invoke-ScaffoldTestGit -Root $root -ArgumentList @('config', '--global', 'core.excludesFile', $excludePath)

        Invoke-NovaModuleInitializationWorkflow -WorkflowContext $context

        Invoke-ScaffoldTestGit -Root $context.Layout.Project -ArgumentList @('ls-tree', '-r', '--name-only', 'HEAD') | Should -Be '.gitignore'
    }

    It 'does not create an empty commit when every generated file is ignored' {
        $excludePath = Join-Path $root 'global-ignore'
        Set-Content -LiteralPath $excludePath -Value '*'
        $null = Invoke-ScaffoldTestGit -Root $root -ArgumentList @('config', '--global', 'core.excludesFile', $excludePath)

        Invoke-NovaModuleInitializationWorkflow -WorkflowContext $context -WarningVariable warnings -WarningAction SilentlyContinue

        (Invoke-NovaGitCommand -ProjectRoot $context.Layout.Project -Arguments @('rev-parse', '--verify', 'HEAD')).ExitCode | Should -Not -Be 0
        $warnings -join ' ' | Should -Match 'No generated files.*initial commit'
    }

    It 'warns without inventing identity when Git <Missing> is missing' -TestCases @(
        @{ Missing = 'user.name' },
        @{ Missing = 'user.email' }
    ) {
        param($Missing)
        $null = Invoke-ScaffoldTestGit -Root $root -ArgumentList @('config', '--global', '--unset-all', $Missing)
        $originalConfig = Get-Content -LiteralPath $env:GIT_CONFIG_GLOBAL -Raw

        Invoke-NovaModuleInitializationWorkflow -WorkflowContext $context -WarningVariable warnings -WarningAction SilentlyContinue

        Test-Path -LiteralPath $context.Layout.ProjectJsonFile | Should -BeTrue
        (Invoke-NovaGitCommand -ProjectRoot $context.Layout.Project -Arguments @('rev-parse', '--verify', 'HEAD')).ExitCode | Should -Not -Be 0
        $warnings -join ' ' | Should -Match 'user.name.*user.email'
        Get-Content -LiteralPath $env:GIT_CONFIG_GLOBAL -Raw | Should -BeExactly $originalConfig
        Invoke-ScaffoldTestGit -Root $context.Layout.Project -ArgumentList @('diff', '--cached', '--name-only') | Should -BeNullOrEmpty
    }

    It 'leaves an enclosing <State> repository and its index unchanged' -TestCases @(
        @{ State = 'unborn' },
        @{ State = 'committed' },
        @{ State = 'dirty' }
    ) {
        param($State)
        $null = Invoke-ScaffoldTestGit -Root $root -ArgumentList @('init')
        if ($State -ne 'unborn') {
            Set-Content -LiteralPath (Join-Path $root 'existing.txt') -Value 'Original'
            $null = Invoke-ScaffoldTestGit -Root $root -ArgumentList @('add', '--', 'existing.txt')
            $null = Invoke-ScaffoldTestGit -Root $root -ArgumentList @('commit', '-m', 'fixture: existing')
        }
        if ($State -eq 'dirty') {
            Add-Content -LiteralPath (Join-Path $root 'existing.txt') -Value 'Staged'
            $null = Invoke-ScaffoldTestGit -Root $root -ArgumentList @('add', '--', 'existing.txt')
            Add-Content -LiteralPath (Join-Path $root 'existing.txt') -Value 'Unstaged'
        }
        $beforeHead = Invoke-NovaGitCommand -ProjectRoot $root -Arguments @('rev-parse', '--verify', 'HEAD')
        $beforeIndex = Invoke-ScaffoldTestGit -Root $root -ArgumentList @('diff', '--cached')
        $beforeWorktree = Invoke-ScaffoldTestGit -Root $root -ArgumentList @('diff')
        $beforeConfig = Get-Content -LiteralPath (Join-Path $root '.git/config') -Raw

        Invoke-NovaModuleInitializationWorkflow -WorkflowContext $context -WarningAction SilentlyContinue

        Test-Path -LiteralPath (Join-Path $context.Layout.Project '.git') | Should -BeFalse
        (Invoke-NovaGitCommand -ProjectRoot $root -Arguments @('rev-parse', '--verify', 'HEAD')).Output | Should -Be $beforeHead.Output
        Invoke-ScaffoldTestGit -Root $root -ArgumentList @('diff', '--cached') | Should -Be $beforeIndex
        Invoke-ScaffoldTestGit -Root $root -ArgumentList @('diff') | Should -Be $beforeWorktree
        Get-Content -LiteralPath (Join-Path $root '.git/config') -Raw | Should -BeExactly $beforeConfig
    }
}
