function Get-NovaProjectPackageOutputDirectorySettingsTable {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Output directory settings is the domain term represented by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$PackageSettings
    )

    $outputDirectoryValue = if ( $PackageSettings.Contains('OutputDirectory')) {
        $PackageSettings['OutputDirectory']
    }
    else {
        $null
    }

    if ($outputDirectoryValue -is [System.Collections.IDictionary]) {
        return [ordered]@{} + $outputDirectoryValue
    }

    return [ordered]@{
        Path = $outputDirectoryValue
    }
}
