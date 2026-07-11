BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/InvokeNovaUpdateNotificationPreferenceChange.ps1')

    function Write-NovaUpdateNotificationPreference {param([bool]$PrereleaseNotificationsEnabled)}
    function Get-NovaUpdateNotificationPreferenceStatus {return [pscustomobject]@{PrereleaseNotificationsEnabled = $true; SettingsPath = '/tmp/x.json'}}
    function Write-Message {param([string]$Text, [string]$color)}
}

Describe 'Test-NovaUpdateNotificationPreferenceChangeWhatIfEnabled' {
    It 'returns true when WorkflowParams.WhatIf is enabled' {
        $workflowContext = [pscustomobject]@{WorkflowParams = @{WhatIf = $true}}
        Test-NovaUpdateNotificationPreferenceChangeWhatIfEnabled -WorkflowContext $workflowContext | Should -BeTrue
    }

    It 'returns false when WorkflowParams.WhatIf is not enabled' {
        $workflowContext = [pscustomobject]@{WorkflowParams = @{}}
        Test-NovaUpdateNotificationPreferenceChangeWhatIfEnabled -WorkflowContext $workflowContext | Should -BeFalse
    }
}

Describe 'Get-NovaUpdateNotificationPreferenceChangeCommandLine' {
    It 'returns the disable command line when prerelease notifications are being turned off' {
        $workflowContext = [pscustomobject]@{PrereleaseNotificationsEnabled = $false}
        Get-NovaUpdateNotificationPreferenceChangeCommandLine -WorkflowContext $workflowContext | Should -Be 'Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications'
    }
}

Describe 'Invoke-NovaUpdateNotificationPreferenceChange' {
    BeforeEach {
        Mock Write-Message {}
    }

    It 'writes the requested preference and returns the resulting status' {
        Mock Write-NovaUpdateNotificationPreference {}
        Mock Get-NovaUpdateNotificationPreferenceStatus {return [pscustomobject]@{PrereleaseNotificationsEnabled = $false; SettingsPath = '/tmp/x.json'}}

        $workflowContext = [pscustomobject]@{
            PrereleaseNotificationsEnabled = $false
            Action = 'Disable prerelease self-update notifications'
            Target = '/tmp/x.json'
            WorkflowParams = @{}
        }
        $status = Invoke-NovaUpdateNotificationPreferenceChange -WorkflowContext $workflowContext -ShouldRun

        Should -Invoke Write-NovaUpdateNotificationPreference -Times 1 -ParameterFilter {
            $PrereleaseNotificationsEnabled -eq $false
        }
        Should -Invoke Get-NovaUpdateNotificationPreferenceStatus -Times 1
        Should -Invoke Write-Message -Times 4
        Should -Invoke Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Prerelease self-updates are now disabled.' -and $color -eq 'Green'
        }
        Should -Invoke Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Get-NovaUpdateNotificationPreference'
        }
        $status.PrereleaseNotificationsEnabled | Should -BeFalse
    }

    It 'writes a preview summary in WhatIf mode without storing the preference' {
        Mock Write-NovaUpdateNotificationPreference {}
        Mock Get-NovaUpdateNotificationPreferenceStatus {}

        $workflowContext = [pscustomobject]@{
            PrereleaseNotificationsEnabled = $true
            Action = 'Enable prerelease self-update notifications'
            Target = '/tmp/x.json'
            WorkflowParams = @{WhatIf = $true}
        }

        $status = Invoke-NovaUpdateNotificationPreferenceChange -WorkflowContext $workflowContext

        Should -Invoke Write-NovaUpdateNotificationPreference -Times 0
        Should -Invoke Get-NovaUpdateNotificationPreferenceStatus -Times 0
        Should -Invoke Write-Message -Times 4
        Should -Invoke Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Notification preference plan ready: prerelease self-updates enabled' -and $color -eq 'Green'
        }
        Should -Invoke Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Run Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications without -WhatIf when you are ready to store the preference.'
        }
        $status | Should -BeNullOrEmpty
    }
}
