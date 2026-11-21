function ConvertTo-NovaModuleSelfUpdatePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InstalledModule,
        [Parameter(Mandatory)][object]$UpdatePlan,
        [Parameter(Mandatory)][bool]$PrereleaseNotificationsEnabled
    )

    $updateAvailable = $UpdatePlan.Disposition -ceq 'UpdateAvailable'
    $prereleaseTarget = $updateAvailable -and [bool]$UpdatePlan.TargetIsPrerelease
    return [pscustomobject]@{
        ModuleName = $InstalledModule.ModuleName
        CurrentVersion = $InstalledModule.Version
        TargetVersion = if ($updateAvailable) {[string]$UpdatePlan.TargetVersion} else {$null}
        LookupCandidateVersion = [string]$UpdatePlan.TargetVersion
        LookupCandidateChannel = if ($UpdatePlan.TargetIsPrerelease) {'Prerelease'} else {'Stable'}
        LookupRepository = $UpdatePlan.RepositoryName
        Scope = $UpdatePlan.Scope
        PrereleaseNotificationsEnabled = $PrereleaseNotificationsEnabled
        UpdateAvailable = $updateAvailable
        RestartRequired = $UpdatePlan.Disposition -ceq 'AlreadyInstalledRestartRequired'
        Updated = $false
        Cancelled = $false
        IsPrereleaseTarget = $prereleaseTarget
        UsedAllowPrerelease = $prereleaseTarget
    }
}
