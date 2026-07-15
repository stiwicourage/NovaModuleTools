BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/GetNovaTestWorkflowContext.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaTestWorkflowContext.TestSupport.ps1')
}

Describe 'Get-NovaTestWorkflowContext' {
    BeforeEach {
        $script:lastRunPathRequest = $null
        $script:lastResultPathRequest = $null
        $script:lastExecutionConfigurationRequest = $null
        $script:lastImportModuleRequest = $null

        Mock Test-ProjectSchema {}
        Mock Get-Module {
            @(
                [pscustomobject]@{Name = 'Pester'; Version = [version]'5.10.0'}
            )
        } -ParameterFilter {$Name -eq 'Pester' -and $ListAvailable}
        Mock Import-Module {
            $script:lastImportModuleRequest = [pscustomobject]@{
                FullyQualifiedName = $PSBoundParameters.FullyQualifiedName
                Force = $PSBoundParameters.Force
            }
        }
        Mock Get-Command {[pscustomobject]@{ScriptBlock = {}}} -ParameterFilter {$CommandType -eq 'Function'}
    }

    It 'configures unit-test execution with coverage enabled and integration tests excluded' {
        $pesterConfig = New-TestPesterConfig
        $projectInfo = New-TestProjectInfo -PesterSettings ([ordered]@{
            CodeCoverage = [ordered]@{
                Enabled = $true
                CoveragePercentTarget = 99
            }
        })

        Mock Get-NovaProjectInfo {$projectInfo}
        Mock New-PesterConfiguration {$pesterConfig}

        $result = Get-NovaTestWorkflowContext -TestOption @{TestMode = 'Unit'} -BoundParameters @{}

        $result.BuildRequested | Should -BeFalse
        $result.CommandName | Should -Be 'Invoke-NovaTest'
        $result.PesterConfig.CodeCoverage.CoveragePercentTarget | Should -Be 99
        $result.PesterConfig.PesterModuleSpecification.SelectedVersion | Should -Be ([version]'5.10.0')
        $result.PesterModuleSpecification.SelectedVersion | Should -Be ([version]'5.10.0')
        $result.PesterSettings.CodeCoverage.Enabled | Should -BeTrue
        $script:lastRunPathRequest.IncludePattern | Should -Be '*.Tests.ps1'
        $script:lastRunPathRequest.ExcludePattern | Should -Be @('*.Integration.Tests.ps1')
        $script:lastResultPathRequest.FileName | Should -Be 'UnitTestResults.xml'
        $result.PesterModuleSpecification.FullyQualifiedName.ModuleName | Should -Be 'Pester'
        $result.PesterModuleSpecification.FullyQualifiedName.RequiredVersion | Should -Be '5.10.0'
        $result.Operation | Should -Be 'Run unit tests and write test results'
    }

    It 'selects the highest supported Pester 5.x version when Pester 6 is also installed' {
        $pesterConfig = New-TestPesterConfig
        $projectInfo = New-TestProjectInfo -PesterSettings ([ordered]@{})

        Mock Get-NovaProjectInfo {$projectInfo}
        Mock New-PesterConfiguration {$pesterConfig}
        Mock Get-Module {
            @(
                [pscustomobject]@{Name = 'Pester'; Version = [version]'6.0.0'}
                [pscustomobject]@{Name = 'Pester'; Version = [version]'5.10.0'}
                [pscustomobject]@{Name = 'Pester'; Version = [version]'5.7.1'}
            )
        } -ParameterFilter {$Name -eq 'Pester' -and $ListAvailable}

        $result = Get-NovaTestWorkflowContext -TestOption @{TestMode = 'Unit'} -BoundParameters @{}

        $result.PesterModuleSpecification.SelectedVersion | Should -Be ([version]'5.10.0')
        $result.PesterConfig.PesterModuleSpecification.SelectedVersion | Should -Be ([version]'5.10.0')
        $result.PesterModuleSpecification.FullyQualifiedName.RequiredVersion | Should -Be '5.10.0'
    }

    It 'configures build-validation execution with coverage disabled and integration-only test discovery' {
        $pesterConfig = New-TestPesterConfig
        $projectInfo = New-TestProjectInfo -PesterSettings ([ordered]@{
            CodeCoverage = [ordered]@{
                Enabled = $true
                CoveragePercentTarget = 99
            }
        })

        Mock Get-NovaProjectInfo {$projectInfo}
        Mock New-PesterConfiguration {$pesterConfig}

        $result = Get-NovaTestWorkflowContext -TestOption @{TestMode = 'BuildValidation'} -BoundParameters @{OverrideWarning = $true}

        $result.BuildRequested | Should -BeTrue
        $result.CommandName | Should -Be 'Test-NovaBuild'
        $result.OverrideWarningRequested | Should -BeTrue
        $result.PesterConfig.CodeCoverage.Enabled | Should -BeFalse
        $result.PesterConfig.CodeCoverage.Path | Should -BeNullOrEmpty
        $result.PesterSettings.CodeCoverage.Enabled | Should -BeFalse
        $script:lastRunPathRequest.IncludePattern | Should -Be '*.Integration.Tests.ps1'
        $script:lastRunPathRequest.ExcludePattern | Should -Be @()
        $script:lastResultPathRequest.FileName | Should -Be 'TestResults.xml'
        $result.Operation | Should -Be 'Build project, run build-validation integration tests, and write test results'
    }

    It 'returns a skip state with actionable guidance when build-validation tests are missing' {
        $pesterConfig = New-TestPesterConfig
        $projectInfo = New-TestProjectInfo -PesterSettings ([ordered]@{})

        Mock Get-NovaProjectInfo {$projectInfo}
        Mock New-PesterConfiguration {$pesterConfig}
        Mock Get-NovaPesterRunPath {@()}

        $result = Get-NovaTestWorkflowContext -TestOption @{TestMode = 'BuildValidation'} -BoundParameters @{}

        $result.TestsDiscovered | Should -BeFalse
        $result.TestDiscoveryMessageLines | Should -HaveCount 4
        $result.TestDiscoveryMessageLines[0] | Should -Be "No build-validation integration tests matching '*.Integration.Tests.ps1' were discovered for NovaProject."
        $result.TestDiscoveryMessageLines[3] | Should -Be 'Use Invoke-NovaTest for unit tests and Test-NovaBuild for build-validation integration tests.'
    }

    It 'expands configured coverage paths into concrete project-relative source files' {
        $projectRoot = Join-Path $TestDrive 'coverage-project'
        foreach ($relativePath in @(
            'src/public/GetAlpha.ps1'
            'src/private/GetBeta.ps1'
            'src/private/quality/GetGamma.ps1'
            'src/private/quality/duplicates/GetDelta.ps1'
            'src/classes/NovaThing.ps1'
        )) {
            $filePath = Join-Path $projectRoot $relativePath
            New-Item -ItemType Directory -Path (Split-Path -Parent $filePath) -Force | Out-Null
            Set-Content -LiteralPath $filePath -Value '# test'
        }

        $pesterConfig = New-TestPesterConfig
        $projectInfo = New-TestProjectInfo -ProjectRoot $projectRoot -PesterSettings ([ordered]@{
            CodeCoverage = [ordered]@{
                Enabled = $true
                Path = @(
                    'src/public/*.ps1'
                    'src/private/**/*.ps1'
                    'src/classes/*.ps1'
                )
            }
        })

        Mock Get-NovaProjectInfo {$projectInfo}
        Mock New-PesterConfiguration {$pesterConfig}

        $result = Get-NovaTestWorkflowContext -TestOption @{TestMode = 'Unit'} -BoundParameters @{}

        $result.PesterConfig.CodeCoverage.Path | Should -Be @(
            'src/public/GetAlpha.ps1'
            'src/private/GetBeta.ps1'
            'src/private/quality/duplicates/GetDelta.ps1'
            'src/private/quality/GetGamma.ps1'
            'src/classes/NovaThing.ps1'
        )
    }

    It 'forwards the guarded Pester configuration override to the execution configuration initializer' {
        $pesterConfig = New-TestPesterConfig
        $projectInfo = New-TestProjectInfo -PesterSettings ([ordered]@{})
        $containerOverride = [pscustomobject]@{
            Type = 'File'
            Item = (Join-Path $projectInfo.ProjectRoot 'tests/Example.Tests.ps1')
            Data = @{ Credential = 'placeholder' }
        }
        $override = @{
            Run = @{
                Container = @($containerOverride)
            }
        }

        Mock Get-NovaProjectInfo {$projectInfo}
        Mock New-PesterConfiguration {$pesterConfig}

        $null = Get-NovaTestWorkflowContext -TestOption @{
            TestMode = 'Unit'
            OutputVerbosity = 'Diagnostic'
            OutputRenderMode = 'Ansi'
            PesterConfigurationOverride = $override
        } -BoundParameters @{}

        $script:lastExecutionConfigurationRequest.ExecutionOption.Keys | Sort-Object | Should -Be @(
            'OutputRenderMode'
            'OutputVerbosity'
            'PesterConfigurationOverride'
            'ProjectRoot'
        )
        $script:lastExecutionConfigurationRequest.ExecutionOption.ProjectRoot | Should -Be $projectInfo.ProjectRoot
        $script:lastExecutionConfigurationRequest.ExecutionOption.OutputVerbosity | Should -Be 'Diagnostic'
        $script:lastExecutionConfigurationRequest.ExecutionOption.OutputRenderMode | Should -Be 'Ansi'
        $script:lastExecutionConfigurationRequest.ExecutionOption.PesterConfigurationOverride | Should -Be $override
    }
}

Describe 'Get-NovaTestWorkflowOperation' {
    It 'returns the build-validation operation text' {
        Get-NovaTestWorkflowOperation -TestMode 'BuildValidation' | Should -Match 'build-validation integration tests'
    }

    It 'returns the unit-test operation text' {
        Get-NovaTestWorkflowOperation -TestMode 'Unit' | Should -Be 'Run unit tests and write test results'
    }
}

Describe 'Get-NovaDiscoveredTestPathState' {
    It 'returns discovered-test state when build-validation tests are present' {
        $result = Get-NovaDiscoveredTestPathState -RunPath @('/tmp/project/tests/public/Get-Thing.Integration.Tests.ps1') -ProjectInfo ([pscustomobject]@{
                TestsDir = '/tmp/project/tests'
                ProjectName = 'NovaProject'
            }) -WorkflowProfile ([pscustomobject]@{
                Mode = 'BuildValidation'
                IncludePattern = '*.Integration.Tests.ps1'
            })

        $result.HasDiscoveredTests | Should -BeTrue
        $result.MessageLines | Should -BeNullOrEmpty
    }

    It 'returns discovered-test state for unit-test workflows when no tests are discovered' {
        $result = Get-NovaDiscoveredTestPathState -RunPath @() -ProjectInfo ([pscustomobject]@{
                TestsDir = '/tmp/project/tests'
                ProjectName = 'NovaProject'
            }) -WorkflowProfile ([pscustomobject]@{
                Mode = 'Unit'
                IncludePattern = '*.Tests.ps1'
            })

        $result.HasDiscoveredTests | Should -BeTrue
        $result.MessageLines | Should -BeNullOrEmpty
    }

    It 'returns the Nova build-validation guidance when no integration tests are discovered' {
        $result = Get-NovaDiscoveredTestPathState -RunPath @() -ProjectInfo ([pscustomobject]@{
                TestsDir = '/tmp/project/tests'
                ProjectName = 'NovaProject'
            }) -WorkflowProfile ([pscustomobject]@{
                Mode = 'BuildValidation'
                IncludePattern = '*.Integration.Tests.ps1'
            })

        $result.HasDiscoveredTests | Should -BeFalse
        $result.MessageLines[0] | Should -Be "No build-validation integration tests matching '*.Integration.Tests.ps1' were discovered for NovaProject."
        $result.MessageLines[1] | Should -Be 'Test-NovaBuild expects build-validation tests under the tests folder, for example /tmp/project/tests/public/Get-CommandName.Integration.Tests.ps1.'
    }
}

Describe 'Assert-NovaPesterAvailable' {
    BeforeEach {
        $script:lastImportModuleRequest = $null
        Mock Import-Module {
            $script:lastImportModuleRequest = [pscustomobject]@{
                FullyQualifiedName = $PSBoundParameters.FullyQualifiedName
                Force = $PSBoundParameters.Force
            }
        }
    }

    It 'stops with Nova.Dependency.PesterDependencyMissing when Pester is missing' {
        Mock Get-Module {@()} -ParameterFilter {$Name -eq 'Pester' -and $ListAvailable}
        {Assert-NovaPesterAvailable -ProjectInfo (New-TestProjectInfo -PesterSettings ([ordered]@{}))} | Should -Throw
    }

    It 'stops when only unsupported Pester 6.x versions are installed' {
        Mock Get-Module {
            @(
                [pscustomobject]@{Name = 'Pester'; Version = [version]'6.0.0'}
            )
        } -ParameterFilter {$Name -eq 'Pester' -and $ListAvailable}

        $thrown = $null
        try {
            Assert-NovaPesterAvailable -ProjectInfo (New-TestProjectInfo -PesterSettings ([ordered]@{}))
        } catch {
            $thrown = $_
        }

        $thrown | Should -Not -BeNullOrEmpty
        $thrown | Should -Match '5.7.1 through 5.10.0'
        $thrown | Should -Match '6.0.0'
    }

    It 'returns the selected supported Pester specification when Pester is available' {
        Mock Get-Module {
            @(
                [pscustomobject]@{Name = 'Pester'; Version = [version]'5.10.0'}
            )
        } -ParameterFilter {$Name -eq 'Pester' -and $ListAvailable}

        $result = Assert-NovaPesterAvailable -ProjectInfo (New-TestProjectInfo -PesterSettings ([ordered]@{}))

        $result.SelectedVersion | Should -Be ([version]'5.10.0')
        $result.FullyQualifiedName.RequiredVersion | Should -Be '5.10.0'
    }
}

Describe 'Get-NovaSupportedPesterModuleSpecification' {
    It 'selects the highest installed version inside Nova''s supported Pester range' {
        $projectInfo = New-TestProjectInfo -PesterSettings ([ordered]@{})
        Mock Get-Module {
            @(
                [pscustomobject]@{Name = 'Pester'; Version = [version]'5.10.1'}
                [pscustomobject]@{Name = 'Pester'; Version = [version]'5.8.0'}
                [pscustomobject]@{Name = 'Pester'; Version = [version]'5.10.0'}
                [pscustomobject]@{Name = 'Pester'; Version = [version]'5.7.1'}
                [pscustomobject]@{Name = 'Pester'; Version = [version]'5.7.0'}
            )
        } -ParameterFilter {$Name -eq 'Pester' -and $ListAvailable}

        $result = Get-NovaSupportedPesterModuleSpecification -ProjectInfo $projectInfo

        $result.MinimumVersion | Should -Be ([version]'5.7.1')
        $result.MaximumVersion | Should -Be ([version]'5.10.0')
        $result.SelectedVersion | Should -Be ([version]'5.10.0')
    }

    It 'falls back to the default supported Pester range when the manifest does not declare Pester' {
        $projectInfo = [pscustomobject]@{
            Pester = [ordered]@{}
            Manifest = [ordered]@{RequiredModules = @()}
        }
        Mock Get-Module {
            @(
                [pscustomobject]@{Name = 'Pester'; Version = [version]'5.7.1'}
            )
        } -ParameterFilter {$Name -eq 'Pester' -and $ListAvailable}

        $result = Get-NovaSupportedPesterModuleSpecification -ProjectInfo $projectInfo

        $result.MinimumVersion | Should -Be ([version]'5.7.1')
        $result.MaximumVersion | Should -Be ([version]'5.10.0')
        $result.SelectedVersion | Should -Be ([version]'5.7.1')
    }

    It 'stops when project.json declares a wider Pester range than Nova supports' {
        $projectInfo = New-TestProjectInfo -PesterSettings ([ordered]@{}) -ManifestRequiredModules @(
            [ordered]@{
                ModuleName = 'Pester'
                ModuleVersion = '5.7.1'
                MaximumVersion = '6.0.0'
            }
        )

        $thrown = $null
        try {
            $null = Get-NovaSupportedPesterModuleSpecification -ProjectInfo $projectInfo
        } catch {
            $thrown = $_
        }

        $thrown | Should -Not -BeNullOrEmpty
        $thrown | Should -Match '5.7.1 through 5.10.0'
        $thrown | Should -Match 'project.json declares Pester from 5.7.1 through 6.0.0'
    }
}

Describe 'Test-NovaPesterModuleVersionSupported' {
    It 'accepts only versions inside Nova''s supported Pester range' {
        $moduleRequirement = Get-NovaPesterModuleRequirement -ProjectInfo (New-TestProjectInfo -PesterSettings ([ordered]@{}))
        $cases = @(
            [pscustomobject]@{Version = '5.7.0'; Expected = $false}
            [pscustomobject]@{Version = '5.7.1'; Expected = $true}
            [pscustomobject]@{Version = '5.10.0'; Expected = $true}
            [pscustomobject]@{Version = '5.10.1'; Expected = $false}
        )

        foreach ($case in $cases) {
            $actual = Test-NovaPesterModuleVersionSupported -Version ([version]$case.Version) -ModuleRequirement $moduleRequirement
            $actual | Should -Be $case.Expected -Because $case.Version
        }
    }
}

Describe 'Get-NovaTestWorkflowProfile' {
    It 'defaults to the unit-test profile' {
        $result = Get-NovaTestWorkflowProfile -TestOption @{}

        $result.Mode | Should -Be 'Unit'
        $result.CommandName | Should -Be 'Invoke-NovaTest'
        $result.CoverageEnabled | Should -BeTrue
    }

    It 'returns the build-validation profile when requested' {
        $result = Get-NovaTestWorkflowProfile -TestOption @{TestMode = 'BuildValidation'}

        $result.Mode | Should -Be 'BuildValidation'
        $result.CommandName | Should -Be 'Test-NovaBuild'
        $result.CoverageEnabled | Should -BeFalse
    }
}

Describe 'Get-NovaTestWorkflowMode' {
    It 'defaults to Unit when the option is absent' {
        Get-NovaTestWorkflowMode -TestOption @{} | Should -Be 'Unit'
    }

    It 'returns the requested mode when present' {
        Get-NovaTestWorkflowMode -TestOption @{TestMode = 'BuildValidation'} | Should -Be 'BuildValidation'
    }
}

Describe 'Get-NovaTestWorkflowPesterConfiguration' {
    It 'returns the project settings unchanged when coverage is enabled' {
        $settings = [pscustomobject]@{CodeCoverage = [pscustomobject]@{Enabled = $true}}
        Get-NovaTestWorkflowPesterConfiguration -ProjectPesterSettings $settings -CoverageEnabled:$true | Should -Be $settings
    }

    It 'returns disabled coverage settings for build validation' {
        (Get-NovaTestWorkflowPesterConfiguration -ProjectPesterSettings $null -CoverageEnabled:$false).CodeCoverage.Enabled | Should -BeFalse
    }
}

Describe 'Get-NovaTestOptionValue' {
    It 'returns the option value when present' {
        Get-NovaTestOptionValue -TestOption @{TagFilter = @('a', 'b')} -Name 'TagFilter' | Should -Be @('a', 'b')
    }

    It 'returns null when the option is absent' {
        Get-NovaTestOptionValue -TestOption @{} -Name 'TagFilter' | Should -BeNullOrEmpty
    }
}

Describe 'Get-NovaConfiguredPesterCoveragePercentTarget' {
    It 'returns null when CodeCoverage is disabled' {
        Get-NovaConfiguredPesterCoveragePercentTarget -ProjectPesterSettings ([ordered]@{CodeCoverage = [ordered]@{Enabled = $false}}) | Should -BeNullOrEmpty
    }

    It 'returns the configured value as double when set' {
        Get-NovaConfiguredPesterCoveragePercentTarget -ProjectPesterSettings ([ordered]@{CodeCoverage = [ordered]@{Enabled = $true; CoveragePercentTarget = 99}}) | Should -Be 99.0
    }
}

Describe 'Get-NovaConfiguredPesterCoveragePath' {
    It 'returns an empty array when CodeCoverage is disabled' {
        @(Get-NovaConfiguredPesterCoveragePath -ProjectPesterSettings ([ordered]@{CodeCoverage = [ordered]@{Enabled = $false; Path = @('src/private/**/*.ps1')}})).Count | Should -Be 0
    }

    It 'returns configured coverage paths when coverage is enabled' {
        Get-NovaConfiguredPesterCoveragePath -ProjectPesterSettings ([ordered]@{CodeCoverage = [ordered]@{Enabled = $true; Path = @('src/public/*.ps1', 'src/private/**/*.ps1')}}) | Should -Be @('src/public/*.ps1', 'src/private/**/*.ps1')
    }
}

Describe 'Get-NovaDisabledPesterCoverageConfiguration' {
    It 'returns disabled coverage settings with empty paths' {
        $result = Get-NovaDisabledPesterCoverageConfiguration

        $result.Enabled | Should -BeFalse
        $result.Path | Should -BeNullOrEmpty
        $result.CoveragePercentTarget | Should -BeNullOrEmpty
    }
}

Describe 'Get-NovaPesterCoverageConfigurationState' {
    It 'returns disabled coverage settings when coverage is disabled for the workflow' {
        $projectInfo = New-TestProjectInfo -PesterSettings ([ordered]@{
            CodeCoverage = [ordered]@{
                Enabled = $true
                CoveragePercentTarget = 99
                Path = @('src/public/*.ps1')
            }
        })

        $result = Get-NovaPesterCoverageConfigurationState -ProjectInfo $projectInfo -CoverageEnabled:$false

        $result.Enabled | Should -BeFalse
        $result.Path | Should -BeNullOrEmpty
        $result.CoveragePercentTarget | Should -BeNullOrEmpty
    }

    It 'returns configured coverage settings when coverage is enabled' {
        $projectRoot = Join-Path $TestDrive 'coverage-values-project'
        $filePath = Join-Path $projectRoot 'src/public/GetAlpha.ps1'
        New-Item -ItemType Directory -Path (Split-Path -Parent $filePath) -Force | Out-Null
        Set-Content -LiteralPath $filePath -Value '# test'
        $projectInfo = New-TestProjectInfo -ProjectRoot $projectRoot -PesterSettings ([ordered]@{
            CodeCoverage = [ordered]@{
                Enabled = $true
                CoveragePercentTarget = 99
                Path = @('src/public/*.ps1')
            }
        })

        $result = Get-NovaPesterCoverageConfigurationState -ProjectInfo $projectInfo -CoverageEnabled:$true

        $result.Enabled | Should -BeTrue
        $result.CoveragePercentTarget | Should -Be 99.0
        $result.Path | Should -Be @('src/public/GetAlpha.ps1')
    }
}

Describe 'Get-NovaPesterSettingValue' {
    It 'returns null for null input' {
        Get-NovaPesterSettingValue -InputObject $null -Name 'X' | Should -BeNullOrEmpty
    }

    It 'reads from IDictionary by key' {
        Get-NovaPesterSettingValue -InputObject @{X = 'value'} -Name 'X' | Should -Be 'value'
    }

    It 'reads named property from PSCustomObject' {
        Get-NovaPesterSettingValue -InputObject ([pscustomobject]@{X = 'value'}) -Name 'X' | Should -Be 'value'
    }
}
