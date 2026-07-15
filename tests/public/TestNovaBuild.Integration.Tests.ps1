BeforeAll {
    $script:projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $script:projectRoot 'tests/TestHelpers/PublicCommandIntegration.ps1')
    Import-NovaPublicCommandIntegrationModule -ProjectRoot $script:projectRoot | Out-Null
}

Describe 'Test-NovaBuild integration' {
    It 'supports WhatIf from the built module' {
        $result = Invoke-NovaPublicCommandIntegrationInIsolatedSession -ProjectRoot $script:projectRoot -ScriptBlock {
            Test-NovaBuild -WhatIf
        }

        $result.ExitCode | Should -Be 0 -Because ($result.Output -join [Environment]::NewLine)
    }

    It 'fails early when the isolated session cannot resolve a supported Pester 5.x module' {
        $result = Invoke-NovaPublicCommandIntegrationInIsolatedSession -ProjectRoot $script:projectRoot -ScriptBlock {
            $temporaryModulePath = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().Guid)
            $originalModulePath = $env:PSModulePath
            try {
                New-NovaPublicCommandIntegrationPesterModule -BasePath $temporaryModulePath -Version '6.0.0' | Out-Null
                $env:PSModulePath = $temporaryModulePath
                Test-NovaBuild -WhatIf
            } finally {
                $env:PSModulePath = $originalModulePath
                Remove-Item -LiteralPath $temporaryModulePath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        $outputText = $result.Output -join [Environment]::NewLine
        $result.ExitCode | Should -Not -Be 0
        $outputText | Should -Match 'Pester'
        $outputText | Should -Match 'Import-Module'
        $outputText | Should -Match 'was not loaded because no valid module file was found|5\.7\.1 through 5\.10\.0'
    }

    It 'warns with actionable guidance when the current project has no build-validation tests' {
        $exampleProjectRoot = Join-Path $script:projectRoot 'src/resources/example'
        $scenarioRoot = Join-Path $TestDrive 'missing-build-validation-tests'
        $null = New-Item -ItemType Directory -Path $scenarioRoot -Force
        Copy-Item -Path (Join-Path $exampleProjectRoot '*') -Destination $scenarioRoot -Recurse -Force
        Remove-Item -LiteralPath (Join-Path $scenarioRoot 'tests/public/Get-ExampleGreeting.Integration.Tests.ps1') -Force

        $result = Invoke-NovaPublicCommandIntegrationInIsolatedSession -ProjectRoot $script:projectRoot -Path $scenarioRoot -ScriptBlock {
            Test-NovaBuild 3>&1
        }

        $result.ExitCode | Should -Be 0 -Because ($result.Output -join [Environment]::NewLine)
        ($result.Output -join [Environment]::NewLine) | Should -Match "No build-validation integration tests matching '\*\.Integration\.Tests\.ps1' were discovered for NovaExampleModule\."
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

        $result = Invoke-NovaPublicCommandIntegrationInIsolatedSession -ProjectRoot $script:projectRoot -Path $scenarioRoot -ScriptBlock {
            Test-NovaBuild
        }

        $result.ExitCode | Should -Be 0 -Because ($result.Output -join [Environment]::NewLine)
    }
}
