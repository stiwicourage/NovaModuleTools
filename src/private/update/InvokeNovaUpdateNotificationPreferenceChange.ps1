function Invoke-NovaUpdateNotificationPreferenceChange {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    Write-NovaUpdateNotificationPreference -PrereleaseNotificationsEnabled:$WorkflowContext.PrereleaseNotificationsEnabled
    return Get-NovaUpdateNotificationPreferenceStatus
}
