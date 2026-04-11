function Get-NovaVersionPreReleaseLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][semver]$CurrentVersion,
        [switch]$PreviewRelease,
        [switch]$StableRelease
    )

    if ($PreviewRelease) {
        return 'preview'
    }

    if ($StableRelease) {
        return $null
    }

    return $CurrentVersion.PreReleaseLabel
}

