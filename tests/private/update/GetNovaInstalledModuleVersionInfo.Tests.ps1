BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/GetNovaInstalledModuleVersionInfo.ps1')

    function Get-NovaCliInstalledVersion {param([object]$Module)}
}

Describe 'Get-NovaInstalledModuleVersionInfo' {
    It 'shapes the installed module info from the resolved version string' {
        Mock Get-NovaCliInstalledVersion {return '1.2.3'}
        $module = [pscustomobject]@{Name = 'NovaModuleTools'}

        $info = Get-NovaInstalledModuleVersionInfo -Module $module

        $info.ModuleName | Should -Be 'NovaModuleTools'
        $info.Version | Should -Be '1.2.3'
        $info.SemanticVersion | Should -Be ([semver]'1.2.3')
        $info.IsPrerelease | Should -BeFalse
    }

    It 'flags prerelease versions through the prerelease label' {
        Mock Get-NovaCliInstalledVersion {return '2.0.0-beta1'}
        $module = [pscustomobject]@{Name = 'NovaModuleTools'}

        (Get-NovaInstalledModuleVersionInfo -Module $module).IsPrerelease | Should -BeTrue
    }
}
