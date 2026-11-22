BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:projectRoot 'tests/TestHelpers/PublicCommandIntegration.ps1')
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Install-NovaCli integration' {
    It 'supports WhatIf for a destination directory from the built module' -Skip:$IsWindows {
        $destinationDirectory = Join-Path $TestDrive 'bin'

        {
            Install-NovaCli -DestinationDirectory $destinationDirectory -WhatIf
        } | Should -Not -Throw

        (Test-Path -LiteralPath (Join-Path $destinationDirectory 'nova')) | Should -BeFalse
    }

    It 'rejects Windows with the unsupported-platform error from the built module' -Skip:(-not $IsWindows) {
        $destinationDirectory = Join-Path $TestDrive 'bin'

        {
            Install-NovaCli -DestinationDirectory $destinationDirectory -WhatIf
        } | Should -Throw -ErrorId 'Nova.Environment.UnsupportedCliInstallPlatform'

        (Test-Path -LiteralPath $destinationDirectory) | Should -BeFalse
    }
}
