. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'tests/TestHelpers/PublicCommandIntegration.ps1')

BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Set-NovaUpdateNotificationPreference integration' {
    It 'supports WhatIf from the built module' {
        {
            Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications -WhatIf
        } | Should -Not -Throw
    }
}
