function Get-NovaResolvedProjectManifestSettings {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Manifest settings is the domain term represented by this resolver.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$ProjectData
    )

    if ($ProjectData.ContainsKey('Manifest') -and $ProjectData['Manifest'] -is [hashtable]) {
        return [ordered]@{} + $ProjectData['Manifest']
    }

    return [ordered]@{}
}

