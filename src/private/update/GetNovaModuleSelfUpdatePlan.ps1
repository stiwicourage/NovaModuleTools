function Get-NovaModuleSelfUpdatePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InstalledModule,
        [Parameter(Mandatory)][pscustomobject]$LookupResult,
        [Parameter(Mandatory)][bool]$PrereleaseNotificationsEnabled
    )

    $stableVersion = Get-NovaAvailableSemanticVersion -VersionInfo $LookupResult.Stable
    if (Test-NovaPrereleaseUpdateAvailable -LookupResult $LookupResult -InstalledVersion $InstalledModule.SemanticVersion -StableVersion $stableVersion -PrereleaseNotificationsEnabled $PrereleaseNotificationsEnabled) {
        return ConvertTo-NovaModuleSelfUpdatePlan -InstalledModule $InstalledModule -PrereleaseNotificationsEnabled:$PrereleaseNotificationsEnabled -TargetVersion $LookupResult.Prerelease.Version -PrereleaseTarget
    }

    if (Test-NovaStableUpdateAvailable -StableVersion $stableVersion -InstalledVersion $InstalledModule.SemanticVersion) {
        return ConvertTo-NovaModuleSelfUpdatePlan -InstalledModule $InstalledModule -PrereleaseNotificationsEnabled:$PrereleaseNotificationsEnabled -TargetVersion $LookupResult.Stable.Version
    }

    return ConvertTo-NovaModuleSelfUpdatePlan -InstalledModule $InstalledModule -PrereleaseNotificationsEnabled:$PrereleaseNotificationsEnabled
}




