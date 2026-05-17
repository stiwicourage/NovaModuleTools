BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/InvokeNovaGitCommand.ps1')
}

Describe 'Test-NovaGitCommandAvailable' {
    It 'returns true when git is on the PATH' {
        Mock Get-Command {return [pscustomobject]@{Name = 'git'}}

        Test-NovaGitCommandAvailable | Should -BeTrue
    }

    It 'returns false when git is missing' {
        Mock Get-Command {return $null}

        Test-NovaGitCommandAvailable | Should -BeFalse
    }
}

Describe 'Get-NovaGitCommandOutputText' {
    It 'joins output lines with a newline and trims the result' {
        $result = Get-NovaGitCommandOutputText -Result ([pscustomobject]@{ExitCode = 0; Output = @('line1', 'line2', '')})

        $result | Should -Be ("line1$( [Environment]::NewLine )line2")
    }

    It 'returns an empty string when output is empty' {
        Get-NovaGitCommandOutputText -Result ([pscustomobject]@{ExitCode = 0; Output = @()}) | Should -Be ''
    }
}
