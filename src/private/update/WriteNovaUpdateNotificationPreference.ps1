function Write-NovaUpdateNotificationPreference {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][bool]$PrereleaseNotificationsEnabled
    )

    $settings = [ordered]@{
        PrereleaseNotificationsEnabled = $PrereleaseNotificationsEnabled
    }

    Write-NovaJsonFileData -LiteralPath (Get-NovaUpdateSettingsFilePath) -Value $settings
}
