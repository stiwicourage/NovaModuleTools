function Write-NovaUpdateNotificationPreference {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][bool]$PrereleaseNotificationsEnabled
    )

    $settingsPath = Get-NovaUpdateSettingsFilePath
    $settingsDirectory = Split-Path -Parent $settingsPath
    if (-not (Test-Path -LiteralPath $settingsDirectory -PathType Container)) {
        $null = New-Item -ItemType Directory -Path $settingsDirectory -Force
    }

    $settings = [ordered]@{
        PrereleaseNotificationsEnabled = $PrereleaseNotificationsEnabled
    }

    $settings |
            ConvertTo-Json |
            Set-Content -LiteralPath $settingsPath -Encoding utf8
}

