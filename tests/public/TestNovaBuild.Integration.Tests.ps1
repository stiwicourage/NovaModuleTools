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

        $result.ExitCode | Should -Be 0 -Because (Get-NovaPublicCommandIntegrationOutputText -Output $result.Output)
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

        $outputText = Get-NovaPublicCommandIntegrationOutputText -Output $result.Output -NormalizeWhitespace
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

        $result.ExitCode | Should -Be 0 -Because (Get-NovaPublicCommandIntegrationOutputText -Output $result.Output)
        (Get-NovaPublicCommandIntegrationOutputText -Output $result.Output -NormalizeWhitespace) | Should -Match "No build-validation integration tests matching '\*\.Integration\.Tests\.ps1' were discovered for NovaExampleModule\."
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

        $result.ExitCode | Should -Be 0 -Because (Get-NovaPublicCommandIntegrationOutputText -Output $result.Output)
    }

    It 'builds a manifest that preserves structured Manifest.PrivateData and generated PSData' {
        $exampleProjectRoot = Join-Path $script:projectRoot 'src/resources/example'
        $scenarioRoot = Join-Path $TestDrive 'private-data-build-validation'
        $projectJsonPath = Join-Path $scenarioRoot 'project.json'
        $integrationTestPath = Join-Path $scenarioRoot 'tests/public/ManifestPrivateData.Integration.Tests.ps1'
        $null = New-Item -ItemType Directory -Path $scenarioRoot -Force
        Copy-Item -Path (Join-Path $exampleProjectRoot '*') -Destination $scenarioRoot -Recurse -Force

        $projectData = Get-Content -LiteralPath $projectJsonPath -Raw | ConvertFrom-Json -AsHashtable
        $projectData.Manifest.Tags = @('Example')
        $projectData.Manifest.PrivateData = [ordered]@{
            'Example Product' = [ordered]@{
                'Feature-Flag' = $true
                ApiVersion = '1'
                RetryCount = 3
                'Nested Data' = [ordered]@{
                    Mode = 'Test'
                }
                Values = @('one', 'two')
                "Owner's Choice" = 'ready'
                '123abc' = $null
            }
        }
        $projectData | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $projectJsonPath

        Set-Content -LiteralPath $integrationTestPath -Value @'
BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $projectFile = Join-Path $projectRoot 'project.json'
    $projectData = Get-Content -LiteralPath $projectFile -Raw | ConvertFrom-Json -AsHashtable
    $script:moduleName = [string]$projectData.ProjectName
    $script:manifestPath = Join-Path $projectRoot "dist/$($script:moduleName)/$($script:moduleName).psd1"
    $script:manifest = Import-PowerShellDataFile -LiteralPath $script:manifestPath
}

Describe 'Manifest.PrivateData integration' {
    It 'preserves native structured values in the generated manifest' {
        $script:manifest.PrivateData['Example Product']['Feature-Flag'] | Should -BeTrue
        $script:manifest.PrivateData['Example Product'].ApiVersion | Should -Be '1'
        $script:manifest.PrivateData['Example Product'].RetryCount | Should -Be 3
        $script:manifest.PrivateData['Example Product']['Nested Data'].Mode | Should -Be 'Test'
        $script:manifest.PrivateData['Example Product'].Values | Should -Be @('one', 'two')
        $script:manifest.PrivateData['Example Product']["Owner's Choice"] | Should -Be 'ready'
        $script:manifest.PrivateData['Example Product']['123abc'] | Should -BeNullOrEmpty
    }

    It 'preserves generated PSData alongside custom PrivateData' {
        $script:manifest.PrivateData.PSData.Tags | Should -Be @('Example')
    }

    It 'writes a manifest that remains importable after the PrivateData rewrite' {
        $content = Get-Content -LiteralPath $script:manifestPath -Raw

        $script:manifest.PrivateData.PSData.Tags | Should -Be @('Example')
        $content | Should -Match "'Example Product' = @\{"
    }
}
'@

        $result = Invoke-NovaPublicCommandIntegrationInIsolatedSession -ProjectRoot $script:projectRoot -Path $scenarioRoot -ScriptBlock {
            Test-NovaBuild
        }

        $result.ExitCode | Should -Be 0 -Because (Get-NovaPublicCommandIntegrationOutputText -Output $result.Output)
    }
}
