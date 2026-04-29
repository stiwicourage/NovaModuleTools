function Get-NovaDefaultUpdateNotificationPreference {
    [CmdletBinding()]
    param()

    return [pscustomobject]@{
        PrereleaseNotificationsEnabled = $true
    }
}

function Read-NovaUpdateNotificationPreference {
    [CmdletBinding()]
    param()

    $settings = Read-NovaJsonFileData -LiteralPath (Get-NovaUpdateSettingsFilePath)
    if ($null -eq $settings) {
        return Get-NovaDefaultUpdateNotificationPreference
    }

    return [pscustomobject]@{
        PrereleaseNotificationsEnabled = if ($null -eq $settings.PrereleaseNotificationsEnabled) {
            $true
        }
        else {
            [bool]$settings.PrereleaseNotificationsEnabled
        }
    }
}
