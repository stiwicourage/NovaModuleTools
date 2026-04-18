function Update-NovaModuleTool {
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias('Update-NovaModuleTools')]
    param()

    $preference = Read-NovaUpdateNotificationPreference
    $installedModule = Get-NovaInstalledModuleVersionInfo
    $lookupResult = Invoke-NovaModuleUpdateLookup -AllowPrereleaseNotifications:$preference.PrereleaseNotificationsEnabled -TimeoutMilliseconds 10000
    if ($null -eq $lookupResult) {
        throw 'Unable to determine a NovaModuleTools update candidate. Try again when the PowerShell Gallery is reachable.'
    }

    $plan = Get-NovaModuleSelfUpdatePlan -InstalledModule $installedModule -LookupResult $lookupResult -PrereleaseNotificationsEnabled $preference.PrereleaseNotificationsEnabled
    if (-not $plan.UpdateAvailable) {
        return $plan
    }

    if ($plan.IsPrereleaseTarget -and -not (Confirm-NovaPrereleaseModuleUpdate -Cmdlet $PSCmdlet -CurrentVersion $plan.CurrentVersion -TargetVersion $plan.TargetVersion)) {
        $plan.Cancelled = $true
        return $plan
    }

    $action = if ($plan.IsPrereleaseTarget) {
        "Update NovaModuleTools to prerelease version $( $plan.TargetVersion )"
    }
    else {
        "Update NovaModuleTools to version $( $plan.TargetVersion )"
    }

    if (-not $PSCmdlet.ShouldProcess($plan.ModuleName, $action)) {
        return $plan
    }

    $null = Invoke-NovaModuleSelfUpdate -ModuleName $plan.ModuleName -AllowPrerelease:$plan.UsedAllowPrerelease
    $plan.Updated = $true
    return $plan
}





