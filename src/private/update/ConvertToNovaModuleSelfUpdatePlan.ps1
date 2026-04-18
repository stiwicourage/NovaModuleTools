function ConvertTo-NovaModuleSelfUpdatePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InstalledModule,
        [Parameter(Mandatory)][bool]$PrereleaseNotificationsEnabled,
        [string]$TargetVersion,
        [switch]$PrereleaseTarget
    )

    return [pscustomobject]@{
        ModuleName = $InstalledModule.ModuleName
        CurrentVersion = $InstalledModule.Version
        TargetVersion = $TargetVersion
        PrereleaseNotificationsEnabled = $PrereleaseNotificationsEnabled
        UpdateAvailable = -not [string]::IsNullOrWhiteSpace($TargetVersion)
        Updated = $false
        Cancelled = $false
        IsPrereleaseTarget = $PrereleaseTarget.IsPresent
        UsedAllowPrerelease = $PrereleaseTarget.IsPresent
    }
}



