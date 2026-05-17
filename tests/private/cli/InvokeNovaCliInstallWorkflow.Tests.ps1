BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/InvokeNovaCliInstallWorkflow.ps1')

    function Copy-NovaCliLauncher {param($SourcePath, $TargetPath, [switch]$Force) return $TargetPath}
    function Test-NovaCliDirectoryOnPath {param($Directory) return $true}
    function Get-NovaModuleReleaseNotesUri {return 'https://example.test/notes'}
}

Describe 'Invoke-NovaCliInstallWorkflow' {
    It 'returns workflow result when directory is on PATH' {
        $ctx = [pscustomobject]@{
            SourcePath = '/tmp/src/nova'
            TargetPath = '/usr/local/bin/nova'
            TargetDirectory = '/usr/local/bin'
            Force = $false
        }
        $result = Invoke-NovaCliInstallWorkflow -WorkflowContext $ctx
        $result.CommandName | Should -Be 'nova'
        $result.InstalledPath | Should -Be '/usr/local/bin/nova'
        $result.DirectoryOnPath | Should -BeTrue
        $result.ReleaseNotesUri | Should -Be 'https://example.test/notes'
    }

    It 'warns when target directory is not on PATH' {
        Mock Test-NovaCliDirectoryOnPath {return $false}
        $ctx = [pscustomobject]@{SourcePath = '/s'; TargetPath = '/t/nova'; TargetDirectory = '/t'; Force = $false}
        Invoke-NovaCliInstallWorkflow -WorkflowContext $ctx -WarningVariable warning -WarningAction SilentlyContinue | Out-Null
        $warning.Count | Should -BeGreaterThan 0
    }
}
