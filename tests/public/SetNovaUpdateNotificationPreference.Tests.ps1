BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/SetNovaUpdateNotificationPreference.ps1')

    function Get-NovaUpdateNotificationPreferenceChangeContext {param([switch]$EnablePrereleaseNotifications, [switch]$DisablePrereleaseNotifications)
        $script:ctxArgs = @{Enable=[bool]$EnablePrereleaseNotifications; Disable=[bool]$DisablePrereleaseNotifications}
        return [pscustomobject]@{Target='nm'; Action='Set'}
    }
    function Invoke-NovaUpdateNotificationPreferenceChange {param($WorkflowContext)
        $script:invoked = $true
        return [pscustomobject]@{Changed=$true}
    }
}

Describe 'Set-NovaUpdateNotificationPreference' {
    BeforeEach {$script:ctxArgs = $null; $script:invoked = $false}

    It 'forwards -EnablePrereleaseNotifications to the context and invokes the workflow' {
        $result = Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications
        $script:ctxArgs.Enable | Should -BeTrue
        $script:invoked | Should -BeTrue
        $result.Changed | Should -BeTrue
    }

    It 'forwards -DisablePrereleaseNotifications to the context' {
        Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications | Out-Null
        $script:ctxArgs.Disable | Should -BeTrue
    }

    It 'returns without invoking the workflow when -WhatIf is set' {
        Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications -WhatIf
        $script:invoked | Should -BeFalse
    }
}
