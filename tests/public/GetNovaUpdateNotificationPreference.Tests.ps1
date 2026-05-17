BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/GetNovaUpdateNotificationPreference.ps1')

    function Get-NovaUpdateNotificationPreferenceStatus {return [pscustomobject]@{PrereleaseNotificationsEnabled=$true}}
}

Describe 'Get-NovaUpdateNotificationPreference' {
    It 'returns the status from Get-NovaUpdateNotificationPreferenceStatus' {
        (Get-NovaUpdateNotificationPreference).PrereleaseNotificationsEnabled | Should -BeTrue
    }
}
