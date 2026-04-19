function Get-NovaResolvedProjectPackageOutputDirectorySettings {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Output directory settings is the domain term represented by this resolver.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$PackageSettings,
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    $outputDirectorySettings = Get-NovaProjectPackageOutputDirectorySettingsTable -PackageSettings $PackageSettings
    Set-NovaPackageSettingDefault -PackageSettings $outputDirectorySettings -Name 'Path' -Value 'artifacts/packages' -TreatWhitespaceAsMissing
    if (-not [System.IO.Path]::IsPathRooted("$( $outputDirectorySettings['Path'] )")) {
        $null = $outputDirectorySettings['Path'] = [System.IO.Path]::Join($ProjectRoot, "$( $outputDirectorySettings['Path'] )")
    }

    Set-NovaPackageSettingDefault -PackageSettings $outputDirectorySettings -Name 'Clean' -Value $true
    $outputDirectorySettings['Clean'] = [bool]$outputDirectorySettings['Clean']
    return $outputDirectorySettings
}

