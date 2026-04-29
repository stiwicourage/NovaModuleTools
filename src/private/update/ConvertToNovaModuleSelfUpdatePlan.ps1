function Get-NovaModuleSelfUpdateLookupCandidate {
    [CmdletBinding()]
    param(
        [pscustomobject]$LookupResult,
        [Parameter(Mandatory)][bool]$PrereleaseNotificationsEnabled
    )

    if ($null -eq $LookupResult) {
        return $null
    }

    if ($PrereleaseNotificationsEnabled -and $null -ne $LookupResult.Prerelease) {
        return $LookupResult.Prerelease
    }

    if ($null -ne $LookupResult.Stable) {
        return $LookupResult.Stable
    }

    return $LookupResult.Prerelease
}

function Get-NovaModuleSelfUpdateLookupRepository {
    [CmdletBinding()]
    param(
        [pscustomobject]$LookupResult,
        [object]$LookupCandidate
    )

    if ($null -ne $LookupCandidate -and $LookupCandidate.PSObject.Properties.Name -contains 'Repository') {
        return $LookupCandidate.Repository
    }

    if ($null -ne $LookupResult -and $LookupResult.PSObject.Properties.Name -contains 'SourceRepository') {
        return $LookupResult.SourceRepository
    }

    return $null
}

function Get-NovaModuleSelfUpdatePlanContext {
    [CmdletBinding()]
    param(
        [pscustomobject]$LookupResult,
        [Parameter(Mandatory)][bool]$PrereleaseNotificationsEnabled
    )

    $lookupCandidate = Get-NovaModuleSelfUpdateLookupCandidate -LookupResult $LookupResult -PrereleaseNotificationsEnabled:$PrereleaseNotificationsEnabled
    $lookupCandidateVersion = if ($null -ne $lookupCandidate -and $lookupCandidate.PSObject.Properties.Name -contains 'Version') {
        $lookupCandidate.Version
    }
    else {
        $null
    }
    $lookupCandidateChannel = if ($null -ne $lookupCandidate -and $lookupCandidate.PSObject.Properties.Name -contains 'Channel') {
        $lookupCandidate.Channel
    }
    else {
        $null
    }

    return [pscustomobject]@{
        LookupCandidateVersion = $lookupCandidateVersion
        LookupCandidateChannel = $lookupCandidateChannel
        LookupRepository = Get-NovaModuleSelfUpdateLookupRepository -LookupResult $LookupResult -LookupCandidate $lookupCandidate
        PrereleaseNotificationsEnabled = $PrereleaseNotificationsEnabled
    }
}

function ConvertTo-NovaModuleSelfUpdatePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$InstalledModule,
        [Parameter(Mandatory)][pscustomobject]$PlanContext,
        [string]$TargetVersion,
        [switch]$PrereleaseTarget
    )

    return [pscustomobject]@{
        ModuleName = $InstalledModule.ModuleName
        CurrentVersion = $InstalledModule.Version
        TargetVersion = $TargetVersion
        LookupCandidateVersion = $PlanContext.LookupCandidateVersion
        LookupCandidateChannel = $PlanContext.LookupCandidateChannel
        LookupRepository = $PlanContext.LookupRepository
        PrereleaseNotificationsEnabled = $PlanContext.PrereleaseNotificationsEnabled
        UpdateAvailable = -not [string]::IsNullOrWhiteSpace($TargetVersion)
        Updated = $false
        Cancelled = $false
        IsPrereleaseTarget = $PrereleaseTarget.IsPresent
        UsedAllowPrerelease = $PrereleaseTarget.IsPresent
    }
}
