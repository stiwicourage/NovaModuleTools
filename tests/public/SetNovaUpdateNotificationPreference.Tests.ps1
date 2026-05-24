BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/SetNovaUpdateNotificationPreference.ps1')
    . (Join-Path $PSScriptRoot 'SetNovaUpdateNotificationPreference.TestSupport.ps1')
}

Describe 'Set-NovaUpdateNotificationPreference' {
    BeforeEach {$script:ctxArgs = $null; $script:invoked = $false; $script:shouldRun = $null}

    It 'forwards -EnablePrereleaseNotifications to the context and invokes the workflow' {
        $result = Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications
        $script:ctxArgs.Enable | Should -BeTrue
        $script:invoked | Should -BeTrue
        $script:shouldRun | Should -BeTrue
        $result.Changed | Should -BeTrue
    }

    It 'forwards -DisablePrereleaseNotifications to the context' {
        Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications | Out-Null
        $script:ctxArgs.Disable | Should -BeTrue
    }

    It 'invokes the workflow with ShouldRun=$false when -WhatIf is set' {
        Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications -WhatIf
        $script:invoked | Should -BeTrue
        $script:shouldRun | Should -BeFalse
        $script:ctxArgs.WhatIf | Should -BeTrue
    }
}
