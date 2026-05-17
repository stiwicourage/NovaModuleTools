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
