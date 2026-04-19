function Get-NovaProjectPackageSettingsTable {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package settings is the domain term represented by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$ProjectData
    )

    if (-not ($ProjectData.ContainsKey('Package') -and $ProjectData['Package'] -is [hashtable])) {
        return [ordered]@{}
    }

    $packageSettings = [ordered]@{} + $ProjectData['Package']
    $null = $packageSettings.Remove('Enabled')
    return $packageSettings
}

