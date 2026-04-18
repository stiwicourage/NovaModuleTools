function Test-NovaPrereleaseUpdateAvailable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$LookupResult,
        [Parameter(Mandatory)][semver]$InstalledVersion,
        [semver]$StableVersion,
        [Parameter(Mandatory)][bool]$PrereleaseNotificationsEnabled
    )

    if (-not $PrereleaseNotificationsEnabled -or $null -eq $LookupResult.Prerelease) {
        return $false
    }

    $prereleaseVersion = [semver]$LookupResult.Prerelease.Version
    if ($prereleaseVersion -le $InstalledVersion) {
        return $false
    }

    return $null -eq $StableVersion -or $LookupResult.Prerelease.Version -ne $LookupResult.Stable.Version
}
