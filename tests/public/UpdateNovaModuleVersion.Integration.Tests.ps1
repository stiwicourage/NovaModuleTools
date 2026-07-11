. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'tests/TestHelpers/PublicCommandIntegration.ps1')

BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Update-NovaModuleVersion integration' {
    It 'supports WhatIf from the built module' {
        $thrown = $null
        Push-Location -LiteralPath $script:projectRoot
        try {
            Update-NovaModuleVersion -WhatIf
        } catch {
            $thrown = $_
        } finally {
            Pop-Location
        }

        $thrown | Should -BeNullOrEmpty
    }
}
