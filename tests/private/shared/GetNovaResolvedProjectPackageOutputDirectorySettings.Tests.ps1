BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaResolvedProjectPackageOutputDirectorySettings.ps1')

    function Get-NovaProjectPackageOutputDirectorySettingsTable {param([System.Collections.IDictionary]$PackageSettings)}
    function Set-NovaPackageSettingDefault {
        param([System.Collections.IDictionary]$PackageSettings, [string]$Name, $Value, [switch]$TreatWhitespaceAsMissing)

        $hasValue = $PackageSettings.Contains($Name)
        if ($hasValue -and $TreatWhitespaceAsMissing) {
            $hasValue = -not [string]::IsNullOrWhiteSpace("$( $PackageSettings[$Name] )")
        }

        if (-not $hasValue) {
            $PackageSettings[$Name] = $Value
        }
    }
}

Describe 'Get-NovaResolvedProjectPackageOutputDirectorySettings' {
    It 'fills in defaults when output directory is unset' {
        Mock Get-NovaProjectPackageOutputDirectorySettingsTable {return [ordered]@{}}

        $result = Get-NovaResolvedProjectPackageOutputDirectorySettings -PackageSettings ([ordered]@{}) -ProjectRoot (Join-Path ([System.IO.Path]::GetTempPath()) 'root')

        $result['Path'] | Should -Match 'artifacts[/\\]packages'
        $result['Clean'] | Should -BeTrue
    }

    It 'preserves a configured rooted Path and Clean=false' {
        $rooted = if ($IsWindows) {'C:\custom\out'} else {'/custom/out'}
        Mock Get-NovaProjectPackageOutputDirectorySettingsTable {return [ordered]@{Path = $rooted; Clean = $false}}

        $result = Get-NovaResolvedProjectPackageOutputDirectorySettings -PackageSettings ([ordered]@{}) -ProjectRoot '/proj'

        $result['Path'] | Should -Be $rooted
        $result['Clean'] | Should -BeFalse
    }

    It 'roots a relative configured Path under the project root' {
        Mock Get-NovaProjectPackageOutputDirectorySettingsTable {return [ordered]@{Path = 'rel/out'}}

        $result = Get-NovaResolvedProjectPackageOutputDirectorySettings -PackageSettings ([ordered]@{}) -ProjectRoot '/proj'

        $result['Path'] | Should -Be ([System.IO.Path]::Join('/proj', 'rel/out'))
    }
}
