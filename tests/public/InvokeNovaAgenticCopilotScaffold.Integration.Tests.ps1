. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'tests/TestHelpers/PublicCommandIntegration.ps1')

BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Invoke-NovaAgenticCopilotScaffold integration' {
    It 'supports WhatIf for a valid Nova project from the built module' {
        $thrown = $null
        Push-Location -LiteralPath $script:projectRoot
        try {
            Invoke-NovaAgenticCopilotScaffold -Path $script:projectRoot -ShortName 'NMT' -WhatIf
        } catch {
            $thrown = $_
        } finally {
            Pop-Location
        }

        $thrown | Should -BeNullOrEmpty
    }
}
