BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/SetNovaPackageSettingDefault.ps1')
}

Describe 'Set-NovaPackageSettingDefault' {
    It 'sets the default value when the key is missing' {
        $settings = [ordered]@{}

        Set-NovaPackageSettingDefault -PackageSettings $settings -Name 'Path' -Value 'artifacts'

        $settings['Path'] | Should -Be 'artifacts'
    }

    It 'does not overwrite an existing value' {
        $settings = [ordered]@{Path = 'existing'}

        Set-NovaPackageSettingDefault -PackageSettings $settings -Name 'Path' -Value 'artifacts'

        $settings['Path'] | Should -Be 'existing'
    }

    It 'overwrites whitespace-only values when TreatWhitespaceAsMissing is set' {
        $settings = [ordered]@{Path = '   '}

        Set-NovaPackageSettingDefault -PackageSettings $settings -Name 'Path' -Value 'artifacts' -TreatWhitespaceAsMissing

        $settings['Path'] | Should -Be 'artifacts'
    }

    It 'leaves whitespace-only values alone when TreatWhitespaceAsMissing is not set' {
        $settings = [ordered]@{Path = '   '}

        Set-NovaPackageSettingDefault -PackageSettings $settings -Name 'Path' -Value 'artifacts'

        $settings['Path'] | Should -Be '   '
    }
}
