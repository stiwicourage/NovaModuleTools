. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'tests/TestHelpers/PublicCommandIntegration.ps1')

BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Publish-NovaModule integration' {
    It 'supports local WhatIf from the built module' {
        $thrown = $null
        Push-Location -LiteralPath $script:projectRoot
        try {
            Publish-NovaModule -Local -WhatIf | Out-Null
        } catch {
            $thrown = $_
        } finally {
            Pop-Location
        }

        $thrown | Should -BeNullOrEmpty
    }
}
