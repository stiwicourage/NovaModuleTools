BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/InitializeNovaModuleScaffold.ps1')
    . (Join-Path $projectRoot 'src/private/scaffold/GetNovaModuleScaffoldPaths.ps1')
    . (Join-Path $projectRoot 'src/private/scaffold/UpdateNovaGitIgnore.ps1')

    . (Join-Path $PSScriptRoot 'InitializeNovaModuleScaffold.TestSupport.ps1')
}

Describe 'Initialize-NovaModuleScaffold' {
    It 'fails with recovery guidance when the project folder already exists' {
        $paths = [pscustomobject]@{Project = (Join-Path $TestDrive 'ExistingProject')}
        $null = New-Item -ItemType Directory -Path $paths.Project -Force

        {
            Initialize-NovaModuleScaffold -Answer @{
                EnableGit = 'No'
                EnableAgenticCopilot = 'No'
            } -Paths $paths
        } | Should -Throw '*Project folder already exists:*Choose a different project name or remove or move the existing folder before running Initialize-NovaModule again.*'
    }

    It 'creates the default .gitignore for the standard scaffold when Git is enabled' {
        $paths = Get-NovaModuleScaffoldLayout -Path $TestDrive -ProjectName 'StandardWithGit'
        Mock Write-Message {}
        Mock New-InitiateGitRepo {}

        Initialize-NovaModuleScaffold -Answer @{
            EnablePester = 'Yes'
            EnableGit = 'Yes'
            EnableAgenticCopilot = 'No'
        } -Paths $paths

        (Test-Path -LiteralPath (Join-Path $paths.Project '.gitignore')) | Should -BeTrue
        Should -Invoke New-InitiateGitRepo -Times 1 -ParameterFilter {$DirectoryPath -eq $paths.Project}
    }

    It 'creates the default .gitignore for the example scaffold when Git is enabled' {
        $paths = Get-NovaModuleScaffoldLayout -Path $TestDrive -ProjectName 'ExampleWithGit'
        Mock Write-Message {}
        Mock New-InitiateGitRepo {}
        Mock Copy-NovaExampleProjectTemplate {
            param($DestinationPath)
            Set-Content -LiteralPath (Join-Path $DestinationPath 'README.md') -Value '# Example' -NoNewline
        }

        Initialize-NovaModuleScaffold -Answer @{
            EnableGit = 'Yes'
            EnableAgenticCopilot = 'No'
        } -Paths $paths -Example

        (Test-Path -LiteralPath (Join-Path $paths.Project '.gitignore')) | Should -BeTrue
        (Test-Path -LiteralPath (Join-Path $paths.Project 'README.md')) | Should -BeTrue
        Should -Invoke New-InitiateGitRepo -Times 1 -ParameterFilter {$DirectoryPath -eq $paths.Project}
    }

    It 'does not create a .gitignore when Git is disabled' {
        $paths = Get-NovaModuleScaffoldLayout -Path $TestDrive -ProjectName 'WithoutGit'
        Mock Write-Message {}
        Mock New-InitiateGitRepo {}

        Initialize-NovaModuleScaffold -Answer @{
            EnablePester = 'No'
            EnableGit = 'No'
            EnableAgenticCopilot = 'No'
        } -Paths $paths

        (Test-Path -LiteralPath (Join-Path $paths.Project '.gitignore')) | Should -BeFalse
        Should -Invoke New-InitiateGitRepo -Times 0
    }
}
