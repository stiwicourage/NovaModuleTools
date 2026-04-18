function Invoke-NovaBuildUpdateNotification {
    [CmdletBinding()]
    param(
        [int]$TimeoutMilliseconds = 3000
    )

    $preference = Read-NovaUpdateNotificationPreference
    $installedModule = Get-NovaInstalledModuleVersionInfo
    $lookupResult = Invoke-NovaModuleUpdateLookup -AllowPrereleaseNotifications:$preference.PrereleaseNotificationsEnabled -TimeoutMilliseconds $TimeoutMilliseconds
    if ($null -eq $lookupResult) {
        return
    }

    $stableVersion = Get-NovaAvailableSemanticVersion -VersionInfo $lookupResult.Stable

    if (Test-NovaStableUpdateAvailable -StableVersion $stableVersion -InstalledVersion $installedModule.SemanticVersion) {
        Write-NovaAvailableModuleUpdateWarning -CurrentVersion $installedModule.Version -AvailableVersion $lookupResult.Stable.Version
    }

    if (-not (Test-NovaPrereleaseUpdateAvailable -LookupResult $lookupResult -InstalledVersion $installedModule.SemanticVersion -StableVersion $stableVersion -PrereleaseNotificationsEnabled $preference.PrereleaseNotificationsEnabled)) {
        return
    }

    Write-NovaAvailableModuleUpdateWarning -CurrentVersion $installedModule.Version -AvailableVersion $lookupResult.Prerelease.Version -Prerelease
}


