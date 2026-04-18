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

Describe 'Coverage gaps for release and git internals' {
    It 'Get-VersionLabelFromCommitSet classifies major, minor, and patch releases' {
        InModuleScope $script:moduleName {
            Get-VersionLabelFromCommitSet -Messages @('feat!: breaking api') | Should -Be 'Major'
            Get-VersionLabelFromCommitSet -Messages @('BREAKING CHANGE: api') | Should -Be 'Major'
            Get-VersionLabelFromCommitSet -Messages @('feat: add capability') | Should -Be 'Minor'
            Get-VersionLabelFromCommitSet -Messages @('fix: patch bug') | Should -Be 'Patch'
            Get-VersionLabelFromCommitSet -Messages @('docs: update readme') | Should -Be 'Patch'
        }
    }

    It 'Get-NovaVersionPartForLabel returns the next semantic version parts' {
        InModuleScope $script:moduleName {
            $major = Get-NovaVersionPartForLabel -CurrentVersion ([semver]'1.2.3') -Label Major
            $minor = Get-NovaVersionPartForLabel -CurrentVersion ([semver]'1.2.3') -Label Minor
            $patch = Get-NovaVersionPartForLabel -CurrentVersion ([semver]'1.2.3') -Label Patch

            "$( $major.Major ).$( $major.Minor ).$( $major.Patch )" | Should -Be '2.0.0'
            "$( $minor.Major ).$( $minor.Minor ).$( $minor.Patch )" | Should -Be '1.3.0'
            "$( $patch.Major ).$( $patch.Minor ).$( $patch.Patch )" | Should -Be '1.2.4'
        }
    }

    It 'Get-NovaVersionPreReleaseLabel returns preview, stable, or the existing prerelease label' {
        InModuleScope $script:moduleName {
            Get-NovaVersionPreReleaseLabel -CurrentVersion ([semver]'1.2.3-preview') -PreviewRelease | Should -Be 'preview'
            $stable = Get-NovaVersionPreReleaseLabel -CurrentVersion ([semver]'1.2.3-preview') -StableRelease
            $stable | Should -BeNullOrEmpty
            Get-NovaVersionPreReleaseLabel -CurrentVersion ([semver]'1.2.3-preview') | Should -Be 'preview'
        }
    }

    It 'Set-NovaModuleVersion writes a new semantic version to project.json' {
        InModuleScope $script:moduleName {
            $projectJsonPath = Join-Path $TestDrive 'project.json'
            Set-Content -LiteralPath $projectJsonPath -Value '{"Version":"1.2.3"}' -Encoding utf8
            Mock Get-NovaProjectInfo {[pscustomobject]@{ProjectJSON = $projectJsonPath}}
            Mock Write-Host {}

            Set-NovaModuleVersion -Label Minor -PreviewRelease -Confirm:$false

            (Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json).Version | Should -Be '1.3.0-preview'
        }
    }

    It 'Publish-NovaBuiltModuleToRepository uses the PSGallery fallback api key when needed' {
        InModuleScope $script:moduleName {
            $originalApiKey = $env:PSGALLERY_API
            try {
                $env:PSGALLERY_API = 'gallery-secret'
                Mock Publish-PSResource {}

                Publish-NovaBuiltModuleToRepository -ProjectInfo ([pscustomobject]@{OutputModuleDir = '/tmp/dist'}) -Repository PSGallery

                Assert-MockCalled Publish-PSResource -Times 1 -ParameterFilter {$Path -eq '/tmp/dist' -and $Repository -eq 'PSGallery' -and $ApiKey -eq 'gallery-secret' -and $Verbose}
            }
            finally {
                $env:PSGALLERY_API = $originalApiKey
            }
        }
    }

    It 'Publish-NovaModule forwards repository publishing through the public command' {
        InModuleScope $script:moduleName {
            $publishAction = {
                param($ProjectInfo, $Repository, $ApiKey)

                Publish-NovaBuiltModuleToRepository @PSBoundParameters
            }

            Mock Get-NovaProjectInfo {[pscustomobject]@{ProjectName = 'NovaModuleTools'; OutputModuleDir = '/tmp/dist'}}
            Mock Invoke-NovaBuild {}
            Mock Test-NovaBuild {}
            Mock Publish-NovaBuiltModuleToRepository {}
            Mock Get-Command {[pscustomobject]@{ScriptBlock = $publishAction}} -ParameterFilter {$Name -eq 'Publish-NovaBuiltModuleToRepository' -and $CommandType -eq 'Function'}

            Publish-NovaModule -Repository PSGallery -ApiKey repo-key

            Assert-MockCalled Publish-NovaBuiltModuleToRepository -Times 1 -ParameterFilter {$Repository -eq 'PSGallery' -and $ApiKey -eq 'repo-key'}
        }
    }

    It 'Publish-NovaBuiltModule routes repository and local publish paths correctly' {
        InModuleScope $script:moduleName {
            $projectInfo = [pscustomobject]@{OutputModuleDir = '/tmp/dist'; ProjectName = 'NovaModuleTools'}
            Mock Test-Path {$true} -ParameterFilter {$LiteralPath -eq '/tmp/dist'}
            Mock Publish-NovaBuiltModuleToRepository {}
            Mock Publish-NovaBuiltModuleToDirectory {}
            Mock Resolve-NovaLocalPublishPath {'/tmp/modules'}

            Publish-NovaBuiltModule -ProjectInfo $projectInfo -Repository PSGallery -ApiKey secret
            Publish-NovaBuiltModule -ProjectInfo $projectInfo

            Assert-MockCalled Publish-NovaBuiltModuleToRepository -Times 1 -ParameterFilter {$Repository -eq 'PSGallery' -and $ApiKey -eq 'secret'}
            Assert-MockCalled Publish-NovaBuiltModuleToDirectory -Times 1 -ParameterFilter {$ModuleDirectoryPath -eq '/tmp/modules'}
        }
    }

    It 'Publish-NovaBuiltModule throws when dist is missing and Resolve-NovaLocalPublishPath returns explicit or local paths' {
        InModuleScope $script:moduleName {
            Mock Test-Path {$false}
            {Publish-NovaBuiltModule -ProjectInfo ([pscustomobject]@{OutputModuleDir = '/tmp/missing'; ProjectName = 'Nova'})} | Should -Throw 'Dist folder is empty*'

            Mock Get-LocalModulePath {'/tmp/local-modules'}
            Resolve-NovaLocalPublishPath -ModuleDirectoryPath '/tmp/custom' | Should -Be '/tmp/custom'
            Resolve-NovaLocalPublishPath | Should -Be '/tmp/local-modules'
        }
    }

    It 'Get-GitCommitMessageForVersionBump returns empty when the project is not a git repository' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'no-git-project'
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null

            $messages = @(Get-GitCommitMessageForVersionBump -ProjectRoot $projectRoot)

            $messages.Count | Should -Be 0
        }
    }

    It 'Get-NovaVersionLabelForBump falls back to Patch when the project is not a git repository' {
        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'no-git-project-for-label'
            New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null

            Get-NovaVersionLabelForBump -ProjectRoot $projectRoot | Should -Be 'Patch'
        }
    }

    It 'Get-NovaVersionLabelForBump throws a clear error when the repository has no commits yet' {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'git is not available in this environment'
            return
        }

        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'empty-git-project'
            Initialize-TestGitRepository -Path $projectRoot

            {Get-NovaVersionLabelForBump -ProjectRoot $projectRoot} | Should -Throw 'Cannot bump version because the repository has no commits yet. Create an initial commit first.'
        }
    }

    It 'Get-NovaVersionLabelForBump throws when there are no commits since the latest tag' {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'git is not available in this environment'
            return
        }

        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'tagged-head-git-project'
            Initialize-TestGitRepository -Path $projectRoot
            New-TestGitCommit -RepositoryPath $projectRoot -Message 'feat: initial release' -File @{Name = 'first.txt'; Content = 'first'}
            New-TestGitTag -RepositoryPath $projectRoot -TagName 'v1.0.0'

            {Get-NovaVersionLabelForBump -ProjectRoot $projectRoot} | Should -Throw 'Cannot bump version because there are no commits since the latest tag.'
        }
    }

    It 'Get-GitCommitMessageForVersionBump returns commits since the latest tag when tags exist' {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'git is not available in this environment'
            return
        }

        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'tagged-git-project'
            Initialize-TestGitRepository -Path $projectRoot
            New-TestGitCommit -RepositoryPath $projectRoot -Message 'feat: initial release' -File @{Name = 'first.txt'; Content = 'first'}
            New-TestGitTag -RepositoryPath $projectRoot -TagName 'v1.0.0'
            New-TestGitCommit -RepositoryPath $projectRoot -Message 'fix: patch bug' -Body 'Detailed patch note' -File @{Name = 'second.txt'; Content = 'second'}
            New-TestGitCommit -RepositoryPath $projectRoot -Message 'docs: update readme' -File @{Name = 'third.txt'; Content = 'third'}

            $messages = @(Get-GitCommitMessageForVersionBump -ProjectRoot $projectRoot)

            $messages.Count | Should -Be 2
            $messages[0] | Should -Be 'docs: update readme'
            $messages[1] | Should -Be "fix: patch bug$( [Environment]::NewLine )Detailed patch note"
        }
    }

    It 'Get-GitCommitMessageForVersionBump returns all commits when no tags exist' {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'git is not available in this environment'
            return
        }

        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'untagged-git-project'
            Initialize-TestGitRepository -Path $projectRoot
            New-TestGitCommit -RepositoryPath $projectRoot -Message 'feat: add capability' -Body 'Implements the new path' -File @{Name = 'first.txt'; Content = 'first'}
            New-TestGitCommit -RepositoryPath $projectRoot -Message 'chore: tidy metadata' -File @{Name = 'second.txt'; Content = 'second'}

            $messages = @(Get-GitCommitMessageForVersionBump -ProjectRoot $projectRoot)

            $messages.Count | Should -Be 2
            $messages[0] | Should -Be 'chore: tidy metadata'
            $messages[1] | Should -Be "feat: add capability$( [Environment]::NewLine )Implements the new path"
        }
    }

    It 'Get-GitCommitMessageForVersionBump returns empty when the git directory exists but git log fails' {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Set-ItResult -Skipped -Because 'git is not available in this environment'
            return
        }

        InModuleScope $script:moduleName {
            $projectRoot = Join-Path $TestDrive 'broken-git-project'
            New-Item -ItemType Directory -Path (Join-Path $projectRoot '.git') -Force | Out-Null

            $messages = @(Get-GitCommitMessageForVersionBump -ProjectRoot $projectRoot)

            $messages.Count | Should -Be 0
        }
    }

    It 'Get-ResourceFilePath falls back cleanly and throws when no candidate exists' {
        InModuleScope $script:moduleName {
            Mock Get-NovaProjectInfo {throw 'not a project'}
            Mock Test-Path {$false}

            {Get-ResourceFilePath -FileName 'missing.json'} | Should -Throw 'Resource file not found: missing.json*'
        }
    }
}


