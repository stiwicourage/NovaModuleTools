BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliInstallWorkflowContext.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaCliInstallWorkflowContext.TestSupport.ps1')
}

Describe 'Get-NovaCliInstallWorkflowContext' {
    It 'rejects Windows hosts' -Skip:(-not $IsWindows) {
        {Get-NovaCliInstallWorkflowContext} | Should -Throw '*macOS/Linux only*'
    }

    It 'returns a populated context when the target does not exist (POSIX)' -Skip:$IsWindows {
        Mock Get-NovaCliInstallDirectory {return ([System.IO.Path]::GetTempPath().TrimEnd([System.IO.Path]::DirectorySeparatorChar))}
        $context = Get-NovaCliInstallWorkflowContext -DestinationDirectory '/tmp/install-' -Force
        $context.SourcePath | Should -Be '/src/nova'
        $context.Force | Should -BeTrue
        $context.Action | Should -Be 'Install nova CLI launcher'
    }

    It 'throws when target exists and -Force is not set (POSIX)' -Skip:$IsWindows {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        Set-Content -LiteralPath (Join-Path $tempDir 'nova') -Value 'x'
        try {
            Mock Get-NovaCliInstallDirectory {return $tempDir}
            {Get-NovaCliInstallWorkflowContext} | Should -Throw '*Target file already exists*'
        } finally {
            Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
