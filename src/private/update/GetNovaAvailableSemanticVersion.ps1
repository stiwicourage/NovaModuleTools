function Get-NovaAvailableSemanticVersion {
    [CmdletBinding()]
    param(
        [object]$VersionInfo
    )

    if ($null -eq $VersionInfo) {
        return $null
    }

    return [semver]$VersionInfo.Version
}
