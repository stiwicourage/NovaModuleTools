function Get-NovaModuleSelfUpdateWorkflowContext {
    [CmdletBinding()]
    param(
        [pscustomobject]$Preference,
        [pscustomobject]$InstalledModule,
        [pscustomobject]$LookupResult,
        [int]$TimeoutMilliseconds = 10000
    )

    $resolvedPreference = if ($null -ne $Preference) {
        $Preference
    }
    else {
        Read-NovaUpdateNotificationPreference
    }
    $resolvedInstalledModule = if ($null -ne $InstalledModule) {
        $InstalledModule
    }
    else {
        Get-NovaInstalledModuleVersionInfo
    }
    $resolvedLookupResult = if ($null -ne $LookupResult) {
        $LookupResult
    }
    else {
        Invoke-NovaModuleUpdateLookup -AllowPrereleaseNotifications:$resolvedPreference.PrereleaseNotificationsEnabled -TimeoutMilliseconds $TimeoutMilliseconds
    }

    if ($null -eq $resolvedLookupResult) {
        Stop-NovaOperation -Message 'Unable to determine a NovaModuleTools update candidate. Try again when the PowerShell Gallery is reachable.' -ErrorId 'Nova.Dependency.ModuleSelfUpdateCandidateUnavailable' -Category ResourceUnavailable -TargetObject 'NovaModuleTools'
    }

    $plan = Get-NovaModuleSelfUpdatePlan -InstalledModule $resolvedInstalledModule -LookupResult $resolvedLookupResult -PrereleaseNotificationsEnabled $resolvedPreference.PrereleaseNotificationsEnabled
    $action = if ($plan.IsPrereleaseTarget) {
        "Update NovaModuleTools to prerelease version $( $plan.TargetVersion )"
    }
    else {
        "Update NovaModuleTools to version $( $plan.TargetVersion )"
    }

    return [pscustomobject]@{
        Preference = $resolvedPreference
        InstalledModule = $resolvedInstalledModule
        LookupResult = $resolvedLookupResult
        Plan = $plan
        Action = $action
    }
}
