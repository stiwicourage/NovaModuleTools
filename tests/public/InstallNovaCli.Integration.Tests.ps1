. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'tests/TestHelpers/PublicCommandIntegration.ps1')

BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Install-NovaCli integration' {
    It 'supports WhatIf for a destination directory from the built module' {
        $destinationDirectory = Join-Path $TestDrive 'bin'

        {
            Install-NovaCli -DestinationDirectory $destinationDirectory -WhatIf
        } | Should -Not -Throw

        (Test-Path -LiteralPath (Join-Path $destinationDirectory 'nova')) | Should -BeFalse
    }
}
