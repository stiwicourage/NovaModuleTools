BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetGitCommitMessagesForVersionBump.ps1')

    function Test-GitRepositoryIsAvailable {param($ProjectRoot) return $true}
    function Invoke-NovaGitCommand {param($ProjectRoot, $Arguments) return [pscustomobject]@{ExitCode=0; Output=@()}}
    function Get-NovaGitCommandOutputText {param($Result) return ($Result.Output -join "`n")}
}

Describe 'Get-GitCommitMessageForVersionBump' {
    It 'returns an empty array when no git repository is available' {
        Mock Test-GitRepositoryIsAvailable {return $false}
        $messages = Get-GitCommitMessageForVersionBump -ProjectRoot '/proj'
        @($messages).Count | Should -Be 0
    }

    It 'returns parsed commit messages when git is available' {
        Mock Invoke-NovaGitCommand {return [pscustomobject]@{ExitCode=0; Output=@('feat: a','body','--END-COMMIT--','fix: b','--END-COMMIT--')}}
        $messages = Get-GitCommitMessageForVersionBump -ProjectRoot '/proj'
        @($messages).Count | Should -BeGreaterThan 0
    }
}

Describe 'Get-NovaVersionBumpCommitLogResult' {
    It 'uses lastTag..HEAD range when a last tag was detected' {
        Mock Invoke-NovaGitCommand {return [pscustomobject]@{ExitCode=0; Output=@('out')}}
        $tagResult = [pscustomobject]@{ExitCode=0; Output=@('v1.0.0')}
        $result = Get-NovaVersionBumpCommitLogResult -ProjectRoot '/proj' -Format 'f' -LastTagResult $tagResult
        $result.ExitCode | Should -Be 0
        Should -Invoke Invoke-NovaGitCommand -ParameterFilter {$Arguments -contains 'v1.0.0..HEAD'}
    }

    It 'falls back to plain log when no tag is found' {
        Mock Invoke-NovaGitCommand {return [pscustomobject]@{ExitCode=0; Output=@()}}
        $tagResult = [pscustomobject]@{ExitCode=128; Output=@()}
        Get-NovaVersionBumpCommitLogResult -ProjectRoot '/proj' -Format 'f' -LastTagResult $tagResult | Out-Null
        Should -Invoke Invoke-NovaGitCommand -ParameterFilter {-not ($Arguments -match '\.\.HEAD$')}
    }
}

Describe 'ConvertFrom-NovaVersionBumpCommitLogResult' {
    It 'returns an empty array when the result has a non-zero exit code' {
        $result = [pscustomobject]@{ExitCode=1; Output=@('feat: x')}
        @((ConvertFrom-NovaVersionBumpCommitLogResult -Result $result)).Count | Should -Be 0
    }

    It 'splits commits on the --END-COMMIT-- delimiter and trims them' {
        $result = [pscustomobject]@{ExitCode=0; Output=@('feat: a','body','--END-COMMIT--','fix: b','--END-COMMIT--')}
        $commits = ConvertFrom-NovaVersionBumpCommitLogResult -Result $result
        @($commits).Count | Should -BeGreaterThan 0
    }
}
