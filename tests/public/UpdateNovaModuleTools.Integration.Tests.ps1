. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'tests/TestHelpers/PublicCommandIntegration.ps1')

BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Update-NovaModuleTool integration' {
    It 'exports the legacy alias from the built module' {
        (Get-Alias -Name 'Update-NovaModuleTools').Definition | Should -Be 'Update-NovaModuleTool'
    }

    It 'supports WhatIf from the built module' {
        {
            Update-NovaModuleTool -WhatIf | Out-Null
        } | Should -Not -Throw
    }
}
