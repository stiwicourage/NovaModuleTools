function Get-NovaVersionPreReleaseLabel {
    [CmdletBinding()]
    param(
        [switch]$PreviewRelease,
        [switch]$StableRelease
    )

    if ($PreviewRelease) {
        return 'preview'
    }

    if ($StableRelease) {
        return $null
    }

    return $null
}
