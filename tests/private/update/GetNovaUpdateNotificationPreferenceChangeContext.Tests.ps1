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
        $context = Get-NovaUpdateNotificationPreferenceChangeContext -EnablePrereleaseNotifications -WorkflowParams @{WhatIf = $true}

        $context.PrereleaseNotificationsEnabled | Should -BeTrue
        $context.Action | Should -Be 'Enable prerelease self-update notifications'
        $context.Target | Should -Not -BeNullOrEmpty
        $context.WorkflowParams | Should -BeOfType Hashtable
        $context.WorkflowParams.WhatIf | Should -BeTrue
    }

    It 'returns a disable context when -DisablePrereleaseNotifications is set' {
        $context = Get-NovaUpdateNotificationPreferenceChangeContext -DisablePrereleaseNotifications

        $context.PrereleaseNotificationsEnabled | Should -BeFalse
        $context.Action | Should -Be 'Disable prerelease self-update notifications'
    }

    It 'throws via Stop-NovaOperation when neither switch is provided' {
        {Get-NovaUpdateNotificationPreferenceChangeContext} | Should -Throw '*Example: Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications*'
    }
}
