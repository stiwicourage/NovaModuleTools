function Get-NovaUpdateNotificationPreferenceStatus {
    [CmdletBinding()]
    param()

    $preference = Read-NovaUpdateNotificationPreference
    $settingsPath = Get-NovaUpdateSettingsFilePath
    $settingsFileExists = Test-Path -LiteralPath $settingsPath -PathType Leaf

    $status = [pscustomobject]@{
        PrereleaseNotificationsEnabled = $preference.PrereleaseNotificationsEnabled
        StableReleaseNotificationsEnabled = $true
        SettingsPath = $settingsPath
    }

    Write-NovaUpdateNotificationPreferenceStatusVerbose -Status $status -SettingsFileExists:$settingsFileExists
    return $status
}

function Write-NovaUpdateNotificationPreferenceStatusVerbose {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$Status,
        [Parameter(Mandatory)][bool]$SettingsFileExists
    )

    $prereleaseState = Get-NovaUpdateNotificationPreferenceStateText -Enabled:$Status.PrereleaseNotificationsEnabled
    if ($SettingsFileExists) {
        Write-Verbose "Prerelease self-updates are $prereleaseState. Stable self-updates remain available. Settings file: $( $Status.SettingsPath )"
        return
    }

    Write-Verbose "No settings file was found at $( $Status.SettingsPath ). Using the default setting: prerelease self-updates are $prereleaseState. Stable self-updates remain available. Use Set-NovaUpdateNotificationPreference to store a different preference."
}

function Get-NovaUpdateNotificationPreferenceStateText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][bool]$Enabled
    )

    if ($Enabled) {
        return 'enabled'
    }

    return 'disabled'
}
