function Get-NovaUpdateNotificationPreferenceChangeContext {
    [CmdletBinding()]
    param(
        [switch]$EnablePrereleaseNotifications,
        [switch]$DisablePrereleaseNotifications
    )

    if ($EnablePrereleaseNotifications.IsPresent) {
        return [pscustomobject]@{
            PrereleaseNotificationsEnabled = $true
            Target = Get-NovaUpdateSettingsFilePath
            Action = 'Enable prerelease update notifications'
        }
    }

    if ($DisablePrereleaseNotifications.IsPresent) {
        return [pscustomobject]@{
            PrereleaseNotificationsEnabled = $false
            Target = Get-NovaUpdateSettingsFilePath
            Action = 'Disable prerelease update notifications'
        }
    }

    Stop-NovaOperation -Message 'Specify either -EnablePrereleaseNotifications or -DisablePrereleaseNotifications.' -ErrorId 'Nova.Validation.UpdateNotificationPreferenceChangeRequired' -Category InvalidArgument -TargetObject 'PrereleaseNotifications'
}
