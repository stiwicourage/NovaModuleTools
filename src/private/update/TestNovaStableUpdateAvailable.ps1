function Test-NovaStableUpdateAvailable {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [semver]$StableVersion,
        [Parameter(Mandatory)][semver]$InstalledVersion
    )

    return $null -ne $StableVersion -and $StableVersion -gt $InstalledVersion
}
