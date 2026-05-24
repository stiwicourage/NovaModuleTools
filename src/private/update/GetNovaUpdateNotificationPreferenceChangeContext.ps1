function Get-NovaUpdateNotificationPreferenceChangeContext {
    [CmdletBinding()]
    param(
        [switch]$EnablePrereleaseNotifications,
        [switch]$DisablePrereleaseNotifications,
        [hashtable]$WorkflowParams = @{}
    )

    if ($EnablePrereleaseNotifications.IsPresent) {
        return [pscustomobject]@{
            PrereleaseNotificationsEnabled = $true
            Target = Get-NovaUpdateSettingsFilePath
            Action = 'Enable prerelease self-update notifications'
            WorkflowParams = $WorkflowParams
        }
    }

    if ($DisablePrereleaseNotifications.IsPresent) {
        return [pscustomobject]@{
            PrereleaseNotificationsEnabled = $false
            Target = Get-NovaUpdateSettingsFilePath
            Action = 'Disable prerelease self-update notifications'
            WorkflowParams = $WorkflowParams
        }
    }

    Stop-NovaOperation -Message 'Specify either -EnablePrereleaseNotifications or -DisablePrereleaseNotifications. Example: Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications' -ErrorId 'Nova.Validation.UpdateNotificationPreferenceChangeRequired' -Category InvalidArgument -TargetObject 'PrereleaseNotifications'
}
