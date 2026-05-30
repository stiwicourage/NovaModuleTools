BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaResolvedProjectPackageSettings.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaResolvedProjectPackageSettings.TestSupport.ps1')
}

Describe 'ConvertTo-NovaPackageLatestPolicy' {
    It 'returns never for $null' {
        ConvertTo-NovaPackageLatestPolicy -Value $null | Should -Be 'never'
    }
    It 'throws for boolean $true with migration-friendly error' {
        { ConvertTo-NovaPackageLatestPolicy -Value $true } | Should -Throw -ErrorId 'Nova.Validation.InvalidPackageLatestPolicy'
    }
    It 'throws for boolean $false with migration-friendly error' {
        { ConvertTo-NovaPackageLatestPolicy -Value $false } | Should -Throw -ErrorId 'Nova.Validation.InvalidPackageLatestPolicy'
    }
    It 'returns never for whitespace' {
        ConvertTo-NovaPackageLatestPolicy -Value '  ' | Should -Be 'never'
    }
    It 'is case-insensitive for known values' {
        ConvertTo-NovaPackageLatestPolicy -Value 'NEVER' | Should -Be 'never'
        ConvertTo-NovaPackageLatestPolicy -Value 'Stable' | Should -Be 'stable'
        ConvertTo-NovaPackageLatestPolicy -Value 'always' | Should -Be 'always'
    }
    It 'throws for unknown values' {
        { ConvertTo-NovaPackageLatestPolicy -Value 'maybe' } | Should -Throw -ErrorId 'Nova.Validation.InvalidPackageLatestPolicy'
    }
}

Describe 'Get-NovaResolvedProjectPackageSettings' {
    It 'fills defaults and resolves the latest policy' {
        Mock Get-NovaProjectPackageSettingsTable { @{} }
        Mock Get-NovaResolvedProjectPackageTypeList { @('Nuget') }
        Mock Get-NovaResolvedProjectPackageOutputDirectorySettings { @{Path='/out'} }

        $settings = Get-NovaResolvedProjectPackageSettings -ProjectData @{ProjectName='Mod'; Version='1.2.3'; Description='Desc'} -ManifestSettings @{Author='Me'} -ProjectRoot '/repo'

        $settings['Id'] | Should -Be 'Mod'
        $settings['Authors'] | Should -Be 'Me'
        $settings['Description'] | Should -Be 'Desc'
        $settings['PackageFileName'] | Should -Be 'Mod.1.2.3.nupkg'
        $settings['FileNamePattern'] | Should -Be 'Mod*'
        $settings['AddVersionToFileName'] | Should -BeFalse
        $settings['Latest'] | Should -Be 'never'
        $settings['Repositories'] | Should -BeNullOrEmpty
        $settings['Headers'] -is [System.Collections.Specialized.OrderedDictionary] | Should -BeTrue
        $settings['Auth'] -is [System.Collections.Specialized.OrderedDictionary] | Should -BeTrue
    }

    It 'normalizes existing latest=always and preserves user fields' {
        Mock Get-NovaProjectPackageSettingsTable { @{Id='Custom'; Latest='Always'; AddVersionToFileName=$true; Repositories=@('https://a'); Headers=@{H='v'}} }
        Mock Get-NovaResolvedProjectPackageTypeList { @() }
        Mock Get-NovaResolvedProjectPackageOutputDirectorySettings { @{} }

        $settings = Get-NovaResolvedProjectPackageSettings -ProjectData @{ProjectName='Mod'; Version='1.0.0'} -ManifestSettings @{Author='Me'} -ProjectRoot '/repo'

        $settings['Id'] | Should -Be 'Custom'
        $settings['Latest'] | Should -Be 'always'
        $settings['AddVersionToFileName'] | Should -BeTrue
        $settings['Repositories'].Count | Should -Be 1
    }
}
