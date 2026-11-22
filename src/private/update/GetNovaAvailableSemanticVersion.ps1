function Get-NovaAvailableSemanticVersion {
    [CmdletBinding()]
    [OutputType([semver])]
    param(
        [object]$VersionInfo
    )

    if ($null -eq $VersionInfo) {
        return $null
    }

    return [semver]$VersionInfo.Version
}
