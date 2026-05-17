BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/GetNovaUpdateNotificationPreferenceStatus.ps1')

    function Read-NovaUpdateNotificationPreference {return [pscustomobject]@{PrereleaseNotificationsEnabled = $true}}
    function Get-NovaUpdateSettingsFilePath {return '/tmp/nova-settings.json'}
}

Describe 'Get-NovaUpdateNotificationPreferenceStatus' {
    It 'returns the stored preference along with the settings file path' {
        Mock Read-NovaUpdateNotificationPreference {return [pscustomobject]@{PrereleaseNotificationsEnabled = $false}}
        Mock Get-NovaUpdateSettingsFilePath {return '/some/path/settings.json'}

        $status = Get-NovaUpdateNotificationPreferenceStatus

        $status.PrereleaseNotificationsEnabled | Should -BeFalse
        $status.StableReleaseNotificationsEnabled | Should -BeTrue
        $status.SettingsPath | Should -Be '/some/path/settings.json'
    }
}
