function Get-NovaModuleSelfUpdateWorkflowContext {
    [CmdletBinding()]
    param(
        [pscustomobject]$Preference,
        [pscustomobject]$InstalledModule,
        [object]$UpdatePlan,
        [hashtable]$WorkflowParams = @{}
    )

    $resolvedPreference = if ($null -ne $Preference) {
        $Preference
    } else {
        Read-NovaUpdateNotificationPreference
    }
    $resolvedInstalledModule = if ($null -ne $InstalledModule) {
        $InstalledModule
    } else {
        Get-NovaInstalledModuleVersionInfo
    }
    $resolvedUpdatePlan = if ($null -ne $UpdatePlan) {
        $UpdatePlan
    } else {
        Get-NovaPSModuleUpdatePlan -Module $resolvedInstalledModule.Module -PrereleaseNotificationsEnabled $resolvedPreference.PrereleaseNotificationsEnabled
    }

    $plan = Get-NovaModuleSelfUpdatePlan -InstalledModule $resolvedInstalledModule -UpdatePlan $resolvedUpdatePlan -PrereleaseNotificationsEnabled $resolvedPreference.PrereleaseNotificationsEnabled
    $action = if ($plan.IsPrereleaseTarget) {
        "Update NovaModuleTools to prerelease version $( $plan.TargetVersion )"
    } else {
        "Update NovaModuleTools to version $( $plan.TargetVersion )"
    }

    return [pscustomobject]@{
        Preference = $resolvedPreference
        InstalledModule = $resolvedInstalledModule
        UpdatePlan = $resolvedUpdatePlan
        WorkflowParams = $WorkflowParams
        Plan = $plan
        Action = $action
    }
}
