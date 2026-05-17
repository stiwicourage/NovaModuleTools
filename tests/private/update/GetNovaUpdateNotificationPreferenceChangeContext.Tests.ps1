BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/GetNovaUpdateNotificationPreferenceChangeContext.ps1')

    function Stop-NovaOperation {
        param([string]$Message, [string]$ErrorId, $Category, $TargetObject)
        throw $Message
    }

    function Get-NovaUpdateSettingsFilePath {return '/tmp/nova-settings.json'}
}

Describe 'Get-NovaUpdateNotificationPreferenceChangeContext' {
    BeforeEach {
        Mock Get-NovaUpdateSettingsFilePath {return '/tmp/nova-settings.json'}
    }

    It 'returns an enable context when -EnablePrereleaseNotifications is set' {
        $context = Get-NovaUpdateNotificationPreferenceChangeContext -EnablePrereleaseNotifications

        $context.PrereleaseNotificationsEnabled | Should -BeTrue
        $context.Action | Should -Be 'Enable prerelease update notifications'
        $context.Target | Should -Not -BeNullOrEmpty
    }

    It 'returns a disable context when -DisablePrereleaseNotifications is set' {
        $context = Get-NovaUpdateNotificationPreferenceChangeContext -DisablePrereleaseNotifications

        $context.PrereleaseNotificationsEnabled | Should -BeFalse
        $context.Action | Should -Be 'Disable prerelease update notifications'
    }

    It 'throws via Stop-NovaOperation when neither switch is provided' {
        {Get-NovaUpdateNotificationPreferenceChangeContext} | Should -Throw '*Specify either*'
    }
}
