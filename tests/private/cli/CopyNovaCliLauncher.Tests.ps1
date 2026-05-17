BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/CopyNovaCliLauncher.ps1')

    function Set-NovaCliExecutablePermission {param([string]$Path)}
}

Describe 'Copy-NovaCliLauncher' {
    It 'copies the launcher and sets execute permission' {
        $sourcePath = [System.IO.Path]::GetTempFileName()
        Set-Content -LiteralPath $sourcePath -Value 'launcher'
        $targetDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $targetPath = Join-Path $targetDirectory 'nova'
        try {
            Mock Set-NovaCliExecutablePermission {}
            Copy-NovaCliLauncher -SourcePath $sourcePath -TargetPath $targetPath -Force | Should -Be $targetPath
            Test-Path -LiteralPath $targetPath | Should -BeTrue
            Should -Invoke Set-NovaCliExecutablePermission -Times 1 -Exactly
        } finally {
            Remove-Item -LiteralPath $sourcePath -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $targetDirectory -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
