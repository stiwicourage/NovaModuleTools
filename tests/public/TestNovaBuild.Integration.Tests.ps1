BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:projectRoot 'tests/TestHelpers/PublicCommandIntegration.ps1')
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Test-NovaBuild integration' {
    It 'supports WhatIf from the built module' {
        {
            Invoke-NovaPublicCommandIntegrationInProjectRoot -ProjectRoot $script:projectRoot -ScriptBlock {
                Test-NovaBuild -WhatIf
            }
        } | Should -Not -Throw
    }

    It 'fails with actionable guidance when the current project has no build-validation tests' {
        $exampleProjectRoot = Join-Path $script:projectRoot 'src/resources/example'
        $scenarioRoot = Join-Path $TestDrive 'missing-build-validation-tests'
        $null = New-Item -ItemType Directory -Path $scenarioRoot -Force
        Copy-Item -Path (Join-Path $exampleProjectRoot '*') -Destination $scenarioRoot -Recurse -Force
        Remove-Item -LiteralPath (Join-Path $scenarioRoot 'tests/public/Get-ExampleGreeting.Integration.Tests.ps1') -Force

        {
            Invoke-NovaPublicCommandIntegrationInLocation -Path $scenarioRoot -ScriptBlock {
                Test-NovaBuild
            }
        } | Should -Throw '*does not contain any build-validation integration tests matching ''*.Integration.Tests.ps1''*Use Invoke-NovaTest for unit tests and Test-NovaBuild for build-validation integration tests.*'
    }
}
