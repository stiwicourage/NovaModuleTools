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

Describe 'Invoke-NovaGitCommand' {
    It 'runs git in the project root and captures exit code and output' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        try {
            $result = Invoke-NovaGitCommand -ProjectRoot $tempDir -Arguments @('--version')
            $result.ExitCode | Should -Be 0
            ($result.Output -join ' ') | Should -Match 'git'
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
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
