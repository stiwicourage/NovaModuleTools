BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetLocalModulePathErrorMessage.ps1')
}

Describe 'Get-LocalModulePathErrorMessage' {
    It 'mentions the match pattern in the message' {
        $message = Get-LocalModulePathErrorMessage -MatchPattern 'PATTERN'
        $message | Should -Match 'PATTERN'
    }

    It 'uses the Windows phrasing on Windows' -Skip:(-not $IsWindows) {
        Get-LocalModulePathErrorMessage -MatchPattern 'p' | Should -Match '^No windows'
    }

    It 'uses the macOS/Linux phrasing on POSIX' -Skip:$IsWindows {
        Get-LocalModulePathErrorMessage -MatchPattern 'p' | Should -Match '^No macOS/Linux'
    }
}
