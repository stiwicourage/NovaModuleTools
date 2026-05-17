BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaFirstConfiguredValue.ps1')
    . (Join-Path $projectRoot 'src/private/shared/GetNovaSettingsDirectoryPath.ps1')

    function Get-NovaEnvironmentVariableValue {param([string]$Name)}
}

Describe 'Get-NovaSettingsRootPath' {
    It 'returns APPDATA when running on Windows and APPDATA is configured' {
        Mock Get-NovaEnvironmentVariableValue {return '/win/appdata'} -ParameterFilter {$Name -eq 'APPDATA'}

        Get-NovaSettingsRootPath -IsWindowsPlatform $true | Should -Be '/win/appdata'
    }

    It 'falls back to XDG_CONFIG_HOME on non-Windows when set' {
        Mock Get-NovaEnvironmentVariableValue {
            if ($Name -eq 'XDG_CONFIG_HOME') {return '/xdg/config'}
            return $null
        }

        Get-NovaSettingsRootPath -IsWindowsPlatform $false | Should -Be '/xdg/config'
    }

    It 'falls back to $HOME/.config when nothing is configured' {
        Mock Get-NovaEnvironmentVariableValue {return $null}

        Get-NovaSettingsRootPath -IsWindowsPlatform $false | Should -Be (Join-Path $HOME '.config')
    }
}

Describe 'Get-NovaSettingsDirectoryPath' {
    It 'joins the application name to the resolved settings root' {
        Mock Get-NovaEnvironmentVariableValue {return $null}

        $expected = Join-Path (Join-Path $HOME '.config') 'NovaModuleTools'

        Get-NovaSettingsDirectoryPath -ApplicationName 'NovaModuleTools' | Should -Be $expected
    }
}
