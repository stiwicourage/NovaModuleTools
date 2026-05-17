BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/GetNovaTestWorkflowContext.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaTestWorkflowContext.TestSupport.ps1')
}

Describe 'Get-NovaTestWorkflowContext' {
    BeforeEach {
        Mock Test-ProjectSchema {}
        Mock Get-Module {[pscustomobject]@{Name = 'Pester'}} -ParameterFilter {$Name -eq 'Pester' -and $ListAvailable}
        Mock Get-Command {[pscustomobject]@{ScriptBlock = {}}} -ParameterFilter {$CommandType -eq 'Function'}
    }

    It 'configures coverage settings for <Name>' -ForEach @(
        @{
            Name = 'an explicit CoveragePercentTarget'
            PesterSettings = [ordered]@{CodeCoverage = [ordered]@{Enabled = $true; CoveragePercentTarget = 99}}
            AssertResult = {
                param($Result)
                $Result.PesterConfig.CodeCoverage.CoveragePercentTarget | Should -Be 99
            }
        }
        @{
            Name = 'an omitted CoveragePercentTarget'
            PesterSettings = [ordered]@{CodeCoverage = [ordered]@{Enabled = $true}}
            AssertResult = {
                param($Result)
                $Result.PesterConfig.CodeCoverage.CoveragePercentTarget | Should -Be 80
            }
        }
        @{
            Name = 'enabled coverage path ownership in project.json'
            PesterSettings = [ordered]@{CodeCoverage = [ordered]@{Enabled = $true; CoveragePercentTarget = 90}}
            AssertResult = {
                param($Result)
                $Result.PesterConfig.CodeCoverage.Path | Should -BeNullOrEmpty
            }
        }
        @{
            Name = 'disabled coverage'
            PesterSettings = [ordered]@{CodeCoverage = [ordered]@{Enabled = $false}}
            AssertResult = {
                param($Result)
                $Result.PesterConfig.CodeCoverage.Path | Should -BeNullOrEmpty
            }
        }
    ) {
        $pesterConfig = & $script:getPesterConfig
        $projectInfo = & $script:getProjectInfo -PesterSettings $PesterSettings

        Mock Get-NovaProjectInfo {$projectInfo}
        Mock New-PesterConfiguration {$pesterConfig}

        $result = Get-NovaTestWorkflowContext -TestOption @{} -BoundParameters @{}
        & $AssertResult $result
    }
}

Describe 'Get-NovaTestWorkflowOperation' {
    It 'mentions the build step when BuildRequested is true' {
        Get-NovaTestWorkflowOperation -BuildRequested $true | Should -Match 'Build project'
    }
    It 'omits the build step when BuildRequested is false' {
        Get-NovaTestWorkflowOperation -BuildRequested $false | Should -Be 'Run Pester tests and write test results'
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
    It 'returns null when CoveragePercentTarget is empty' {
        Get-NovaConfiguredPesterCoveragePercentTarget -ProjectPesterSettings ([ordered]@{CodeCoverage = [ordered]@{Enabled = $true; CoveragePercentTarget = ''}}) | Should -BeNullOrEmpty
    }
    It 'returns the configured value as double when set' {
        Get-NovaConfiguredPesterCoveragePercentTarget -ProjectPesterSettings ([ordered]@{CodeCoverage = [ordered]@{Enabled = $true; CoveragePercentTarget = 99}}) | Should -Be 99.0
    }
}

Describe 'Get-NovaPesterSettingValue' {
    It 'returns null for null input' {
        Get-NovaPesterSettingValue -InputObject $null -Name 'X' | Should -BeNullOrEmpty
    }
    It 'reads from IDictionary by key' {
        Get-NovaPesterSettingValue -InputObject @{X = 'value'} -Name 'X' | Should -Be 'value'
    }
    It 'returns null from IDictionary when key is missing' {
        Get-NovaPesterSettingValue -InputObject @{Other = 1} -Name 'X' | Should -BeNullOrEmpty
    }
    It 'reads named property from PSCustomObject' {
        Get-NovaPesterSettingValue -InputObject ([pscustomobject]@{X = 'value'}) -Name 'X' | Should -Be 'value'
    }
    It 'returns null when PSCustomObject lacks the property' {
        Get-NovaPesterSettingValue -InputObject ([pscustomobject]@{Other = 1}) -Name 'X' | Should -BeNullOrEmpty
    }
}
