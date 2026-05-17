BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/InvokeNovaUpdateNotificationPreferenceChange.ps1')

    function Write-NovaUpdateNotificationPreference {param([bool]$PrereleaseNotificationsEnabled)}
    function Get-NovaUpdateNotificationPreferenceStatus {return [pscustomobject]@{PrereleaseNotificationsEnabled = $true; SettingsPath = '/tmp/x.json'}}
}

Describe 'Invoke-NovaUpdateNotificationPreferenceChange' {
    It 'writes the requested preference and returns the resulting status' {
        Mock Write-NovaUpdateNotificationPreference {}
        Mock Get-NovaUpdateNotificationPreferenceStatus {return [pscustomobject]@{PrereleaseNotificationsEnabled = $false; SettingsPath = '/tmp/x.json'}}

        $workflowContext = [pscustomobject]@{PrereleaseNotificationsEnabled = $false; Action = 'Disable prerelease update notifications'; Target = '/tmp/x.json'}
        $status = Invoke-NovaUpdateNotificationPreferenceChange -WorkflowContext $workflowContext

        Assert-MockCalled Write-NovaUpdateNotificationPreference -Times 1 -ParameterFilter {
            $PrereleaseNotificationsEnabled -eq $false
        }
        Assert-MockCalled Get-NovaUpdateNotificationPreferenceStatus -Times 1
        $status.PrereleaseNotificationsEnabled | Should -BeFalse
    }
}
