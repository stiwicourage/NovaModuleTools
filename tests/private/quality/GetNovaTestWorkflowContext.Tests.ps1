BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/GetNovaTestWorkflowContext.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaTestWorkflowContext.TestSupport.ps1')
}

Describe 'Get-NovaTestWorkflowContext' {
    BeforeEach {
        $script:lastRunPathRequest = $null
        $script:lastResultPathRequest = $null

        Mock Test-ProjectSchema {}
        Mock Get-Module {[pscustomobject]@{Name = 'Pester'}} -ParameterFilter {$Name -eq 'Pester' -and $ListAvailable}
        Mock Get-Command {[pscustomobject]@{ScriptBlock = {}}} -ParameterFilter {$CommandType -eq 'Function'}
    }

    It 'configures unit-test execution with coverage enabled and integration tests excluded' {
        $pesterConfig = & $script:getPesterConfig
        $projectInfo = & $script:getProjectInfo -PesterSettings ([ordered]@{
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
        $result.PesterSettings.CodeCoverage.Enabled | Should -BeTrue
        $script:lastRunPathRequest.IncludePattern | Should -Be '*.Tests.ps1'
        $script:lastRunPathRequest.ExcludePattern | Should -Be @('*.Integration.Tests.ps1')
        $script:lastResultPathRequest.FileName | Should -Be 'UnitTestResults.xml'
        $result.Operation | Should -Be 'Run unit tests and write test results'
    }

    It 'configures build-validation execution with coverage disabled and integration-only test discovery' {
        $pesterConfig = & $script:getPesterConfig
        $projectInfo = & $script:getProjectInfo -PesterSettings ([ordered]@{
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

        $pesterConfig = & $script:getPesterConfig
        $projectInfo = & $script:getProjectInfo -ProjectRoot $projectRoot -PesterSettings ([ordered]@{
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
}

Describe 'Get-NovaTestWorkflowOperation' {
    It 'returns the build-validation operation text' {
        Get-NovaTestWorkflowOperation -TestMode 'BuildValidation' | Should -Match 'build-validation integration tests'
    }

    It 'returns the unit-test operation text' {
        Get-NovaTestWorkflowOperation -TestMode 'Unit' | Should -Be 'Run unit tests and write test results'
    }
}

Describe 'Assert-NovaPesterAvailable' {
    It 'stops with Nova.Dependency.PesterDependencyMissing when Pester is missing' {
        Mock Get-Module {@()} -ParameterFilter {$Name -eq 'Pester' -and $ListAvailable}
        {Assert-NovaPesterAvailable} | Should -Throw
    }

    It 'returns silently when Pester is available' {
        Mock Get-Module {@([pscustomobject]@{Name = 'Pester'})} -ParameterFilter {$Name -eq 'Pester' -and $ListAvailable}
        {Assert-NovaPesterAvailable} | Should -Not -Throw
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

Describe 'Disable-NovaPesterCoverageConfiguration' {
    It 'disables coverage and clears configured paths' {
        $pesterConfig = & $script:getPesterConfig
        Disable-NovaPesterCoverageConfiguration -PesterConfig $pesterConfig

        $pesterConfig.CodeCoverage.Enabled | Should -BeFalse
        $pesterConfig.CodeCoverage.Path | Should -BeNullOrEmpty
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
