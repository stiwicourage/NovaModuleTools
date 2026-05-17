BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/SetNovaCliExecutablePermission.ps1')

    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'Set-NovaCliExecutablePermission' {
    It 'returns silently on Windows hosts' -Skip:(-not $IsWindows) {
        {Set-NovaCliExecutablePermission -Path 'C:/tmp/nova'} | Should -Not -Throw
    }

    It 'invokes chmod successfully on POSIX' -Skip:$IsWindows {
        $temp = [System.IO.Path]::GetTempFileName()
        try {
            {Set-NovaCliExecutablePermission -Path $temp} | Should -Not -Throw
        } finally {
            Remove-Item -LiteralPath $temp -ErrorAction SilentlyContinue
        }
    }
}
