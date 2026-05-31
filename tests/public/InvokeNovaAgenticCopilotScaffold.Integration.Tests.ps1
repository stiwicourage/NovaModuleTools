BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:projectRoot 'tests/TestHelpers/PublicCommandIntegration.ps1')
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Invoke-NovaAgenticCopilotScaffold integration' {
    It 'supports WhatIf for a valid Nova project from the built module' {
        {
            Invoke-NovaPublicCommandIntegrationInProjectRoot -ProjectRoot $script:projectRoot -ScriptBlock {
                Invoke-NovaAgenticCopilotScaffold -Path $script:projectRoot -ShortName 'NMT' -WhatIf
            }
        } | Should -Not -Throw
    }
}
