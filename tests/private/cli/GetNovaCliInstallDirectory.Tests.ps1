BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliInstallDirectory.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaCliInstallDirectory.TestSupport.ps1')
}

Describe 'Get-NovaCliInstallDirectory' {
    It 'returns the absolute form of an explicit destination directory' {
        $result = Get-NovaCliInstallDirectory -DestinationDirectory '/tmp/dest'
        $result | Should -Be ([System.IO.Path]::GetFullPath('/tmp/dest'))
    }

    It 'returns $HOME/.local/bin when HOME is set' {
        Mock Get-NovaEnvironmentVariableValue {return '/home/u'}
        Get-NovaCliInstallDirectory | Should -Be ([System.IO.Path]::Join('/home/u', '.local', 'bin'))
    }

    It 'throws when HOME is missing' {
        Mock Get-NovaEnvironmentVariableValue {return $null}
        {Get-NovaCliInstallDirectory} | Should -Throw '*HOME environment variable*'
    }
}
