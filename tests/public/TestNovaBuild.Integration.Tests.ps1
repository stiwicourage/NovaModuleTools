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

    It 'warns with actionable guidance when the current project has no build-validation tests' {
        $exampleProjectRoot = Join-Path $script:projectRoot 'src/resources/example'
        $scenarioRoot = Join-Path $TestDrive 'missing-build-validation-tests'
        $null = New-Item -ItemType Directory -Path $scenarioRoot -Force
        Copy-Item -Path (Join-Path $exampleProjectRoot '*') -Destination $scenarioRoot -Recurse -Force
        Remove-Item -LiteralPath (Join-Path $scenarioRoot 'tests/public/Get-ExampleGreeting.Integration.Tests.ps1') -Force

        $warnings = & {
            Invoke-NovaPublicCommandIntegrationInLocation -Path $scenarioRoot -ScriptBlock {
                Test-NovaBuild 3>&1
            }
        }

        $warningMessages = @(
            $warnings |
                Where-Object {$_ -is [System.Management.Automation.WarningRecord]} |
                ForEach-Object Message
        )

        $warningMessages | Should -Contain "No build-validation integration tests matching '*.Integration.Tests.ps1' were discovered for NovaExampleModule."
    }

    It 'passes for a scaffolded example whose project name differs from the packaged template name' {
        $exampleProjectRoot = Join-Path $script:projectRoot 'src/resources/example'
        $scenarioRoot = Join-Path $TestDrive 'renamed-build-validation-example'
        $projectJsonPath = Join-Path $scenarioRoot 'project.json'
        $null = New-Item -ItemType Directory -Path $scenarioRoot -Force
        Copy-Item -Path (Join-Path $exampleProjectRoot '*') -Destination $scenarioRoot -Recurse -Force

        $projectData = Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json -AsHashtable
        $projectData.ProjectName = 'BuildValidationExample'
        $projectData | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $projectJsonPath

        {
            Invoke-NovaPublicCommandIntegrationInLocation -Path $scenarioRoot -ScriptBlock {
                Test-NovaBuild
            }
        } | Should -Not -Throw
    }
}
