BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/InvokeNovaCliNotificationCommand.ps1')

    function ConvertFrom-NovaNotificationCliArgument {param([string[]]$Arguments) return 'status'}
    function Get-NovaUpdateNotificationPreference {return 'pref'}
    function Set-NovaUpdateNotificationPreference {param([switch]$EnablePrereleaseNotifications, [switch]$DisablePrereleaseNotifications)
        if ($EnablePrereleaseNotifications) {return 'enabled'}
        if ($DisablePrereleaseNotifications) {return 'disabled'}
    }
}

Describe 'Invoke-NovaCliNotificationCommand' {
    It 'returns status by default' {
        Invoke-NovaCliNotificationCommand -Arguments @() -CommonParameters @{} -MutatingCommonParameters @{} | Should -Be 'pref'
    }

    It 'enables prerelease notifications for enable mode' {
        Mock ConvertFrom-NovaNotificationCliArgument {return 'enable'}
        Invoke-NovaCliNotificationCommand -Arguments @() -CommonParameters @{} -MutatingCommonParameters @{} | Should -Be 'enabled'
    }

    It 'disables prerelease notifications for disable mode' {
        Mock ConvertFrom-NovaNotificationCliArgument {return 'disable'}
        Invoke-NovaCliNotificationCommand -Arguments @() -CommonParameters @{} -MutatingCommonParameters @{} | Should -Be 'disabled'
    }
}
