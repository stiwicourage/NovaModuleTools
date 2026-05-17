BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetNovaCliInstalledVersion.ps1')

    function Get-NovaModulePsDataValue {param([string]$Name, $Module) return $null}
}

Describe 'Get-NovaCliInstalledVersion' {
    It 'returns the version when no prerelease label is set' {
        $module = [pscustomobject]@{Version = [version]'1.2.3'}
        Mock Get-NovaModulePsDataValue {return ''}
        Get-NovaCliInstalledVersion -Module $module | Should -Be '1.2.3'
    }

    It 'appends the prerelease label when present' {
        $module = [pscustomobject]@{Version = [version]'1.2.3'}
        Mock Get-NovaModulePsDataValue {return 'beta1'}
        Get-NovaCliInstalledVersion -Module $module | Should -Be '1.2.3-beta1'
    }
}
