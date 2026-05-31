BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:projectRoot 'tests/TestHelpers/PublicCommandIntegration.ps1')
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Invoke-NovaTest integration' {
    It 'supports WhatIf from the built module' {
        {
            Invoke-NovaPublicCommandIntegrationInProjectRoot -ProjectRoot $script:projectRoot -ScriptBlock {
                Invoke-NovaTest -WhatIf
            }
        } | Should -Not -Throw
    }
}
