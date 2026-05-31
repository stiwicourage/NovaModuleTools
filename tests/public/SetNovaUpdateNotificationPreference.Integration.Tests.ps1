BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:projectRoot 'tests/TestHelpers/PublicCommandIntegration.ps1')
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Set-NovaUpdateNotificationPreference integration' {
    It 'supports WhatIf from the built module' {
        {
            Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications -WhatIf
        } | Should -Not -Throw
    }
}
