BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/ConfirmNovaCliAction.ps1')

    function Stop-NovaOperation {
        param([string]$Message, [string]$ErrorId, [System.Management.Automation.ErrorCategory]$Category, $TargetObject)
        $exception = [System.Exception]::new($Message)
        $record = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
        throw $record
    }
    function Get-NovaEnvironmentVariableValue {param([string]$Name) return $null}
}

Describe 'Get-NovaCliConfirmDecision' {
    It 'returns true for Y/A (case-insensitive)' {
        Get-NovaCliConfirmDecision -KeyChar 'Y' | Should -BeTrue
        Get-NovaCliConfirmDecision -KeyChar 'y' | Should -BeTrue
        Get-NovaCliConfirmDecision -KeyChar 'A' | Should -BeTrue
        Get-NovaCliConfirmDecision -KeyChar 'a' | Should -BeTrue
    }
    It 'returns false for N/L/S' {
        Get-NovaCliConfirmDecision -KeyChar 'N' | Should -BeFalse
        Get-NovaCliConfirmDecision -KeyChar 'L' | Should -BeFalse
        Get-NovaCliConfirmDecision -KeyChar 'S' | Should -BeFalse
    }
    It 'returns null for other keys' {
        Get-NovaCliConfirmDecision -KeyChar 'X' | Should -BeNullOrEmpty
    }
}

Describe 'Get-NovaCliNativeConsoleReadKeyReader' {
    It 'returns a scriptblock referencing [Console]::ReadKey' {
        $sb = Get-NovaCliNativeConsoleReadKeyReader
        $sb | Should -BeOfType ([scriptblock])
        $sb.ToString() | Should -Match 'Console.*ReadKey'
    }
}

Describe 'Get-NovaCliConsoleReadKeyReader' {
    It 'returns a scriptblock invoking Invoke-NovaCliNativeConsoleReadKey' {
        $sb = Get-NovaCliConsoleReadKeyReader
        $sb.ToString() | Should -Match 'Invoke-NovaCliNativeConsoleReadKey'
    }
}

Describe 'Invoke-NovaCliNativeConsoleReadKey' {
    It 'uses the provided reader scriptblock' {
        $reader = { [pscustomobject]@{KeyChar = [char]'Q'} }
        $result = Invoke-NovaCliNativeConsoleReadKey -Reader $reader
        $result.KeyChar | Should -Be 'Q'
    }
}

Describe 'Invoke-NovaCliConsoleReadKey' {
    It 'invokes the reader returned by Get-NovaCliConsoleReadKeyReader' {
        Mock Get-NovaCliConsoleReadKeyReader { { [pscustomobject]@{KeyChar = [char]'Z'} } }
        (Invoke-NovaCliConsoleReadKey).KeyChar | Should -Be 'Z'
    }
}

Describe 'Read-NovaCliConsoleKeyChar' {
    It 'returns the KeyChar from Invoke-NovaCliConsoleReadKey' {
        Mock Invoke-NovaCliConsoleReadKey { [pscustomobject]@{KeyChar = [char]'Y'} }
        Read-NovaCliConsoleKeyChar | Should -Be 'Y'
    }
}

Describe 'Read-NovaCliPromptKey' {
    It 'returns the read key on success' {
        Mock Read-NovaCliConsoleKeyChar { [char]'N' }
        Read-NovaCliPromptKey | Should -Be 'N'
    }
    It 'returns char 0 on failure' {
        Mock Read-NovaCliConsoleKeyChar { throw 'no console' }
        Read-NovaCliPromptKey | Should -Be ([char]0)
    }
}

Describe 'Get-NovaCliConfirmResponseKey' {
    It 'returns the first char when env var is set' {
        Mock Get-NovaEnvironmentVariableValue { 'Yes' }
        Get-NovaCliConfirmResponseKey | Should -Be 'Y'
    }
    It 'returns null when env var is empty/whitespace' {
        Mock Get-NovaEnvironmentVariableValue { '' }
        Get-NovaCliConfirmResponseKey | Should -BeNullOrEmpty
    }
    It 'returns null when env var is not set' {
        Mock Get-NovaEnvironmentVariableValue { $null }
        Get-NovaCliConfirmResponseKey | Should -BeNullOrEmpty
    }
}

Describe 'Get-NovaCliCommandPromptKey' {
    It 'uses configured response when available' {
        Mock Get-NovaCliConfirmResponseKey { [char]'N' }
        Mock Write-Host {}
        Mock Read-NovaCliPromptKey { [char]'X' }
        Get-NovaCliCommandPromptKey -Message 'go?' | Should -Be 'N'
        Assert-MockCalled Read-NovaCliPromptKey -Times 0
    }
    It 'falls back to console prompt when no configured response' {
        Mock Get-NovaCliConfirmResponseKey { $null }
        Mock Write-Host {}
        Mock Read-NovaCliPromptKey { [char]'A' }
        Get-NovaCliCommandPromptKey -Message 'go?' | Should -Be 'A'
        Assert-MockCalled Read-NovaCliPromptKey -Times 1
    }
}

Describe 'Get-NovaCliCommandCancellationInfo' {
    It 'returns suspend-specific info for S' {
        $info = Get-NovaCliCommandCancellationInfo -Command 'build' -KeyChar 'S'
        $info.ErrorId | Should -Be 'Nova.Workflow.CliSuspendNotSupported'
        $info.Message | Should -Match 'Suspend'
    }
    It 'returns generic cancellation info for N' {
        $info = Get-NovaCliCommandCancellationInfo -Command 'build' -KeyChar 'N'
        $info.ErrorId | Should -Be 'Nova.Workflow.CliOperationCancelled'
        $info.Message | Should -Be 'Operation cancelled.'
    }
}

Describe 'Confirm-NovaCliCommandAction' {
    It 'returns silently when user presses Enter' {
        Mock Get-NovaCliCommandPromptKey { [char]13 }
        Mock Write-Host {}
        { Confirm-NovaCliCommandAction -Command 'build' } | Should -Not -Throw
    }
    It 'returns silently when user presses Y' {
        Mock Get-NovaCliCommandPromptKey { [char]'Y' }
        Mock Write-Host {}
        { Confirm-NovaCliCommandAction -Command 'build' } | Should -Not -Throw
    }
    It 'throws cancellation when user presses N' {
        Mock Get-NovaCliCommandPromptKey { [char]'N' }
        Mock Write-Host {}
        { Confirm-NovaCliCommandAction -Command 'build' } | Should -Throw -ErrorId 'Nova.Workflow.CliOperationCancelled'
    }
    It 'throws suspend-specific error when user presses S' {
        Mock Get-NovaCliCommandPromptKey { [char]'S' }
        Mock Write-Host {}
        { Confirm-NovaCliCommandAction -Command 'build' } | Should -Throw -ErrorId 'Nova.Workflow.CliSuspendNotSupported'
    }
    It 'loops on invalid keys then accepts Y' {
        $script:keys = @([char]'X', [char]'Q', [char]'Y')
        $script:idx = 0
        Mock Get-NovaCliCommandPromptKey {
            $k = $script:keys[$script:idx]; $script:idx++; return $k
        }
        Mock Write-Host {}
        { Confirm-NovaCliCommandAction -Command 'build' } | Should -Not -Throw
        Assert-MockCalled Get-NovaCliCommandPromptKey -Times 3
    }
}
