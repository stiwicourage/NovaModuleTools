BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/InitiateGitRepo.ps1')

    function Test-NovaGitCommandAvailable {return $true}
    function Invoke-NovaGitCommand {param($ProjectRoot, $Arguments) return [pscustomobject]@{ExitCode=0; Output=@()}}
    function Get-NovaGitCommandOutputText {param($Result) return ($Result.Output -join "`n")}
    function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'New-InitiateGitRepo' {
    BeforeEach {
        $script:dir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $script:dir | Out-Null
    }
    AfterEach {
        Remove-Item -LiteralPath $script:dir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'warns and returns when Git is not installed' {
        Mock Test-NovaGitCommandAvailable {return $false}
        New-InitiateGitRepo -DirectoryPath $script:dir -WarningVariable warn -WarningAction SilentlyContinue
        $warn.Count | Should -BeGreaterThan 0
    }

    It 'warns when a .git folder already exists' {
        New-Item -ItemType Directory -Path (Join-Path $script:dir '.git') | Out-Null
        New-InitiateGitRepo -DirectoryPath $script:dir -WarningVariable warn -WarningAction SilentlyContinue
        $warn.Count | Should -BeGreaterThan 0
    }

    It 'throws when git init fails' {
        Mock Invoke-NovaGitCommand {return [pscustomobject]@{ExitCode=128; Output=@('boom')}}
        {New-InitiateGitRepo -DirectoryPath $script:dir} | Should -Throw '*Failed to initialize Git repo*'
    }

    It 'wraps the exception when Invoke-NovaGitCommand throws' {
        Mock Invoke-NovaGitCommand {throw 'kaboom'}
        {New-InitiateGitRepo -DirectoryPath $script:dir} | Should -Throw '*kaboom*'
    }
}

Describe 'Get-NovaGitInitializationFailureMessage' {
    It 'returns the generic message when result output is empty' {
        Get-NovaGitInitializationFailureMessage -Result ([pscustomobject]@{ExitCode=1; Output=@()}) | Should -Be 'Failed to initialize Git repo.'
    }

    It 'includes git details when available' {
        Get-NovaGitInitializationFailureMessage -Result ([pscustomobject]@{ExitCode=1; Output=@('fatal: x')}) | Should -Match 'fatal: x'
    }
}
