BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/CompleteScaffoldGitRepository.ps1')
    function Test-NovaGitCommandAvailable { return $true }
    function Invoke-NovaGitCommand { param($ProjectRoot, $Arguments) }
    function New-InitiateGitRepo { [CmdletBinding(SupportsShouldProcess)] param($DirectoryPath, [switch]$PassThru) return $true }
    function Write-Message { param($InputObject, $color) }
    function Stop-NovaOperation { param($Message, $ErrorId, $Category, $TargetObject) throw $Message }
}

Describe 'Complete-ScaffoldGitRepository' -Tag 'NovaInitGit' {
    BeforeEach {
        $projectRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $null = New-Item -ItemType Directory -Path $projectRoot
        Set-Content -LiteralPath (Join-Path $projectRoot 'project.json') -Value '{}'
        $context = [pscustomobject]@{
            Layout = [pscustomobject]@{ Project = $projectRoot }
            AnswerSet = @{ EnableAgenticCopilot = 'No' }
            Example = $false
        }
        Mock Write-Message {}
        Mock New-InitiateGitRepo { return $true }
        Mock Invoke-NovaGitCommand {
            param($ProjectRoot, $Arguments)
            if ($Arguments -contains '--git-dir') {
                return [pscustomobject]@{ ExitCode = 128; Output = @() }
            }
            $output = if ($Arguments -contains '--others') { @("project.json`0") } else { @() }
            return [pscustomobject]@{ ExitCode = 0; Output = $output }
        }
    }

    Context 'initialization ownership' {
        It 'never stages or commits when initialization did not create a repository' {
            Mock New-InitiateGitRepo { return $null }

            Complete-ScaffoldGitRepository -WorkflowContext $context

            Should -Invoke Invoke-NovaGitCommand -Times 0 -ParameterFilter { $Arguments -contains 'commit' -or $Arguments -contains 'add' }
        }

        It 'warns and preserves the scaffold when Git is unavailable' {
            Mock Test-NovaGitCommandAvailable { return $false }

            Complete-ScaffoldGitRepository -WorkflowContext $context -WarningVariable warnings -WarningAction SilentlyContinue

            $warnings -join ' ' | Should -Match 'Git is not installed'
            Should -Invoke New-InitiateGitRepo -Times 0
        }

        It 'leaves an existing Git directory or worktree pointer untouched' -TestCases @(
            @{ ItemType = 'Directory' },
            @{ ItemType = 'File' }
        ) {
            param($ItemType)
            $null = New-Item -ItemType $ItemType -Path (Join-Path $projectRoot '.git')

            Complete-ScaffoldGitRepository -WorkflowContext $context -WarningAction SilentlyContinue

            Should -Invoke New-InitiateGitRepo -Times 0
            Should -Invoke Invoke-NovaGitCommand -Times 0 -ParameterFilter { $Arguments -contains 'add' -or $Arguments -contains 'commit' }
        }
    }

    Context 'commit safety and failures' {
        It 'preserves files and the index when the committer identity is unavailable' {
            Mock Invoke-NovaGitCommand {
                return [pscustomobject]@{ ExitCode = 128; Output = @() }
            } -ParameterFilter { $Arguments -contains 'GIT_COMMITTER_IDENT' }

            Complete-ScaffoldGitRepository -WorkflowContext $context -WarningVariable warnings -WarningAction SilentlyContinue

            $warnings -join ' ' | Should -Match 'user.name.*user.email'
            Should -Invoke Invoke-NovaGitCommand -Times 0 -ParameterFilter { $Arguments -contains 'add' -or $Arguments -contains 'commit' }
        }

        It 'does not commit an index supplied by a Git template' {
            Mock Invoke-NovaGitCommand {
                return [pscustomobject]@{ ExitCode = 0; Output = @("user-file.txt`0") }
            } -ParameterFilter { $Arguments -contains '--cached' }

            Complete-ScaffoldGitRepository -WorkflowContext $context -WarningVariable warnings -WarningAction SilentlyContinue

            $warnings -join ' ' | Should -Match 'index already contains files'
            Should -Invoke Invoke-NovaGitCommand -Times 0 -ParameterFilter { $Arguments -contains 'commit' }
        }

        It 'reports a failed <Step> step rather than announcing a successful commit' -TestCases @(
            @{ Step = 'ls-files'; Flag = '--others' },
            @{ Step = 'add'; Flag = 'add' },
            @{ Step = 'commit'; Flag = 'commit' },
            @{ Step = 'HEAD verification'; Flag = '--verify' }
        ) {
            param($Step, $Flag)
            Mock Invoke-NovaGitCommand {
                return [pscustomobject]@{ ExitCode = 1; Output = @() }
            } -ParameterFilter { $Arguments -contains $Flag }

            { Complete-ScaffoldGitRepository -WorkflowContext $context } | Should -Throw '*Git initial commit step failed*preserved*manually*'

            Should -Invoke Write-Message -Times 0 -ParameterFilter { $InputObject -like 'Created initial Git commit*' }
        }

        It 'does not query or stage files when the generated manifest is empty' {
            Remove-Item -LiteralPath (Join-Path $projectRoot 'project.json')

            Complete-ScaffoldGitRepository -WorkflowContext $context -WarningVariable warnings -WarningAction SilentlyContinue

            $warnings -join ' ' | Should -Match 'No generated files'
            Should -Invoke Invoke-NovaGitCommand -Times 0 -ParameterFilter { $Arguments -contains '--others' -or $Arguments -contains 'add' }
        }
    }
}

Describe 'Get-ScaffoldTemplateFileList' -Tag 'NovaInitGit' {
    It 'includes hidden generated files without including Git metadata' {
        $templateRoot = Join-Path $TestDrive 'template'
        $null = New-Item -ItemType Directory -Path (Join-Path $templateRoot '.github'), (Join-Path $templateRoot '.git')
        Set-Content -LiteralPath (Join-Path $templateRoot '.github/settings.json') -Value '{}'
        Set-Content -LiteralPath (Join-Path $templateRoot '.git/config') -Value 'User config'

        @(Get-ScaffoldTemplateFileList -TemplateRoot $templateRoot) | Should -Be @('.github/settings.json')
    }
}
