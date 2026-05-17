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

Describe 'Initialize-NovaModuleScaffold' {
    It 'creates the default .gitignore for the standard scaffold when Git is enabled' {
        InModuleScope $script:moduleName {
            $paths = Get-NovaModuleScaffoldLayout -Path $TestDrive -ProjectName 'StandardWithGit'
            Mock Write-Message {}
            Mock New-InitiateGitRepo {}

            Initialize-NovaModuleScaffold -Answer @{
                EnablePester = 'Yes'
                EnableGit = 'Yes'
                EnableAgenticCopilot = 'No'
            } -Paths $paths

            (Test-Path -LiteralPath (Join-Path $paths.Project '.gitignore')) | Should -BeTrue
            Assert-MockCalled New-InitiateGitRepo -Times 1 -ParameterFilter {$DirectoryPath -eq $paths.Project}
        }
    }

    It 'creates the default .gitignore for the example scaffold when Git is enabled' {
        InModuleScope $script:moduleName {
            $paths = Get-NovaModuleScaffoldLayout -Path $TestDrive -ProjectName 'ExampleWithGit'
            Mock Write-Message {}
            Mock New-InitiateGitRepo {}

            Initialize-NovaModuleScaffold -Answer @{
                EnableGit = 'Yes'
                EnableAgenticCopilot = 'No'
            } -Paths $paths -Example

            (Test-Path -LiteralPath (Join-Path $paths.Project '.gitignore')) | Should -BeTrue
            (Test-Path -LiteralPath (Join-Path $paths.Project 'README.md')) | Should -BeTrue
            Assert-MockCalled New-InitiateGitRepo -Times 1 -ParameterFilter {$DirectoryPath -eq $paths.Project}
        }
    }

    It 'does not create a .gitignore when Git is disabled' {
        InModuleScope $script:moduleName {
            $paths = Get-NovaModuleScaffoldLayout -Path $TestDrive -ProjectName 'WithoutGit'
            Mock Write-Message {}
            Mock New-InitiateGitRepo {}

            Initialize-NovaModuleScaffold -Answer @{
                EnablePester = 'No'
                EnableGit = 'No'
                EnableAgenticCopilot = 'No'
            } -Paths $paths

            (Test-Path -LiteralPath (Join-Path $paths.Project '.gitignore')) | Should -BeFalse
            Assert-MockCalled New-InitiateGitRepo -Times 0
        }
    }
}
