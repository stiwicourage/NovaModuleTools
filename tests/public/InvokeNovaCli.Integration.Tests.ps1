BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:projectRoot 'tests/TestHelpers/PublicCommandIntegration.ps1')
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Invoke-NovaCli integration' {
    It 'returns root help from the built module' {
        $result = Invoke-NovaCli

        $result | Should -Match 'nova'
    }
}
