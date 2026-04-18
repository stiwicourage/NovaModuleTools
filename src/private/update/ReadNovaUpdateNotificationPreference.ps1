function Read-NovaUpdateNotificationPreference {
    [CmdletBinding()]
    param()

    $settingsPath = Get-NovaUpdateSettingsFilePath
    $defaultPreference = [pscustomobject]@{
        PrereleaseNotificationsEnabled = $true
    }

    if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
        return $defaultPreference
    }

    try {
        $settings = Get-Content -LiteralPath $settingsPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        return $defaultPreference
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
