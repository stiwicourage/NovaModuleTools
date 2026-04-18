function Get-NovaUpdateNotificationPreference {
    [CmdletBinding()]
    param()

    $preference = Read-NovaUpdateNotificationPreference

    return [pscustomobject]@{
        PrereleaseNotificationsEnabled = $preference.PrereleaseNotificationsEnabled
        StableReleaseNotificationsEnabled = $true
        SettingsPath = Get-NovaUpdateSettingsFilePath
    }
}

