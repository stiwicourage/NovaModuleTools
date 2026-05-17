BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaVersionLabelForBump.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaVersionLabelForBump.TestSupport.ps1')
}

Describe 'Get-NovaVersionLabelForBump' {
    It 'delegates to Get-VersionLabelFromCommitSet when commit messages are provided' {
        Get-NovaVersionLabelForBump -ProjectRoot '/p' -CommitMessages @('feat: x') | Should -Be 'Major'
    }

    It 'returns Patch when no git repo and no commit messages' {
        Mock Invoke-NovaGitCommand {return [pscustomobject]@{ExitCode=128; Output=@()}}
        Get-NovaVersionLabelForBump -ProjectRoot '/p' | Should -Be 'Patch'
    }

    It 'throws when git repo exists but HEAD is uncommitted' {
        $script:i = 0
        Mock Invoke-NovaGitCommand {
            $script:i += 1
            if ($script:i -eq 1) {[pscustomobject]@{ExitCode=0; Output=@('.git')}}
            else {[pscustomobject]@{ExitCode=128; Output=@()}}
        }
        { Get-NovaVersionLabelForBump -ProjectRoot '/p' } | Should -Throw '*has no commits yet*'
    }

    It 'handles latest-tag commit count resolution for <Name>' -ForEach @(
        @{ Name = 'CI mode with no commits since the latest tag'; CommitCount = '0'; ContinuousIntegrationRequested = $true; ExpectedResult = 'Patch'; ExpectedThrow = $null }
        @{ Name = 'non-CI mode with no commits since the latest tag'; CommitCount = '0'; ContinuousIntegrationRequested = $false; ExpectedThrow = '*no commits since the latest tag*' }
        @{ Name = 'commits since the latest tag'; CommitCount = '3'; ContinuousIntegrationRequested = $false; ExpectedResult = 'Patch'; ExpectedThrow = $null }
    ) {
        Set-NovaVersionLabelGitSequenceMock -CommitCount $CommitCount

        if ($ExpectedThrow) {
            { Get-NovaVersionLabelForBump -ProjectRoot '/p' } | Should -Throw $ExpectedThrow
        }
        else {
            Get-NovaVersionLabelForBump -ProjectRoot '/p' -ContinuousIntegrationRequested:$ContinuousIntegrationRequested | Should -Be $ExpectedResult
        }
    }
}

Describe 'Test-GitRepositoryIsAvailable' {
    It 'returns true on zero exit' {
        Mock Invoke-NovaGitCommand {return [pscustomobject]@{ExitCode=0; Output=@('.git')}}
        Test-GitRepositoryIsAvailable -ProjectRoot '/p' | Should -BeTrue
    }

    It 'returns false on non-zero exit' {
        Mock Invoke-NovaGitCommand {return [pscustomobject]@{ExitCode=128; Output=@()}}
        Test-GitRepositoryIsAvailable -ProjectRoot '/p' | Should -BeFalse
    }
}

Describe 'Test-GitRepositoryHasCommittedHead' {
    It 'returns true when HEAD verifies' {
        Mock Invoke-NovaGitCommand {return [pscustomobject]@{ExitCode=0; Output=@('sha')}}
        Test-GitRepositoryHasCommittedHead -ProjectRoot '/p' | Should -BeTrue
    }
}

Describe 'Test-GitRepositoryHasCommitsSinceLatestTag' {
    It 'returns true when no last tag is found' {
        Mock Invoke-NovaGitCommand {return [pscustomobject]@{ExitCode=128; Output=@()}}
        Test-GitRepositoryHasCommitsSinceLatestTag -ProjectRoot '/p' | Should -BeTrue
    }

    It 'returns false when commit count is exactly 0 since the tag' {
        $script:invocations = 0
        Mock Invoke-NovaGitCommand {
            $script:invocations++
            if ($script:invocations -eq 1) {return [pscustomobject]@{ExitCode=0; Output=@('v1.0.0')}}
            return [pscustomobject]@{ExitCode=0; Output=@('0')}
        }
        Test-GitRepositoryHasCommitsSinceLatestTag -ProjectRoot '/p' | Should -BeFalse
    }
}
