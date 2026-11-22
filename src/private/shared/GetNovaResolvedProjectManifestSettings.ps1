function Get-NovaResolvedProjectManifestSettings {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Manifest settings is the domain term represented by this resolver.')]
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory)][hashtable]$ProjectData
    )

    if ($ProjectData.ContainsKey('Manifest') -and $ProjectData['Manifest'] -is [System.Collections.IDictionary]) {
        return [ordered]@{} + $ProjectData['Manifest']
    }

    return [ordered]@{}
}
