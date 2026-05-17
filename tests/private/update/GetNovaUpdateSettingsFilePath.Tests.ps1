BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/GetNovaUpdateSettingsFilePath.ps1')

    function Get-NovaSettingsDirectoryPath {param([string]$ApplicationName)}
}

Describe 'Get-NovaUpdateSettingsFilePath' {
    It 'returns settings.json under the NovaModuleTools settings directory' {
        Mock Get-NovaSettingsDirectoryPath {return '/home/u/.config/NovaModuleTools'}

        $path = Get-NovaUpdateSettingsFilePath

        $path | Should -Match 'settings\.json$'
        Assert-MockCalled Get-NovaSettingsDirectoryPath -Times 1 -ParameterFilter {
            $ApplicationName -eq 'NovaModuleTools'
        }
    }
}
