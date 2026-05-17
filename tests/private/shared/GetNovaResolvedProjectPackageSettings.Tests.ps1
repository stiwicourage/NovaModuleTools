BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaResolvedProjectPackageSettings.ps1')

    function Stop-NovaOperation {
        param([string]$Message, [string]$ErrorId, [System.Management.Automation.ErrorCategory]$Category, $TargetObject)
        $exception = [System.Exception]::new($Message)
        $record = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
        throw $record
    }
    function Get-NovaProjectPackageSettingsTable {param([hashtable]$ProjectData)}
    function Get-NovaResolvedProjectPackageTypeList {param([hashtable]$PackageSettings)}
    function Get-NovaResolvedProjectPackageOutputDirectorySettings {param([hashtable]$PackageSettings, [string]$ProjectRoot)}
    function Set-NovaPackageSettingDefault {
        param([hashtable]$PackageSettings, [string]$Name, $Value, [switch]$TreatWhitespaceAsMissing)
        $existing = $PackageSettings[$Name]
        $missing = $null -eq $existing
        if (-not $missing -and $TreatWhitespaceAsMissing -and $existing -is [string]) {
            $missing = [string]::IsNullOrWhiteSpace($existing)
        }
        if ($missing) { $PackageSettings[$Name] = $Value }
    }
}

Describe 'ConvertTo-NovaPackageLatestPolicy' {
    It 'returns never for $null' {
        ConvertTo-NovaPackageLatestPolicy -Value $null | Should -Be 'never'
    }
    It 'maps boolean $true to always' {
        ConvertTo-NovaPackageLatestPolicy -Value $true | Should -Be 'always'
    }
    It 'maps boolean $false to never' {
        ConvertTo-NovaPackageLatestPolicy -Value $false | Should -Be 'never'
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
