BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetLocalModulePathPattern.ps1')
}

Describe 'Get-LocalModulePathPattern' {
    It 'returns a Windows pattern on Windows' -Skip:(-not $IsWindows) {
        Get-LocalModulePathPattern | Should -Be '\\Documents\\PowerShell\\Modules'
    }

    It 'returns a POSIX pattern on macOS/Linux' -Skip:$IsWindows {
        Get-LocalModulePathPattern | Should -Be '/\.local/share/powershell/Modules$'
    }
}
