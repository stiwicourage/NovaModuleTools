function Get-NovaModuleSelfUpdatePlanContext {
    param([pscustomobject]$LookupResult, [bool]$PrereleaseNotificationsEnabled)
    return [pscustomobject]@{
        LookupCandidateVersion = $null
        LookupCandidateChannel = $null
        LookupRepository = $null
        PrereleaseNotificationsEnabled = $PrereleaseNotificationsEnabled
    }
}

function Get-NovaAvailableSemanticVersion {
    param([object]$VersionInfo)
    if ($null -eq $VersionInfo) {return $null}
    return [semver]$VersionInfo.Version
}

function Test-NovaPrereleaseUpdateAvailable {
    param([pscustomobject]$LookupResult, [semver]$InstalledVersion, [semver]$StableVersion, [bool]$PrereleaseNotificationsEnabled)
    return $false
}

function Test-NovaStableUpdateAvailable {
    param([semver]$StableVersion, [semver]$InstalledVersion)
    return $false
}

function ConvertTo-NovaModuleSelfUpdatePlan {
    param([pscustomobject]$InstalledModule, [pscustomobject]$PlanContext, [string]$TargetVersion, [switch]$PrereleaseTarget)
    return [pscustomobject]@{
        TargetVersion = $TargetVersion
        IsPrereleaseTarget = $PrereleaseTarget.IsPresent
        UpdateAvailable = -not [string]::IsNullOrWhiteSpace($TargetVersion)
    }
}
