BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaReleasePublishOption.ps1')
}

Describe 'Copy-NovaPublishOption' {
    It 'creates an independent copy of the publish option hashtable' {
        $source = @{a=1; b=2}
        $copy = Copy-NovaPublishOption -PublishOption $source
        $copy['a'] = 99
        $source['a'] | Should -Be 1
        $copy['b'] | Should -Be 2
    }

    It 'returns an empty hashtable when no input is provided' {
        $copy = Copy-NovaPublishOption
        $copy.Keys.Count | Should -Be 0
    }
}

Describe 'Get-NovaReleasePublishOption' {
    It 'copies PublishOption when ParameterSetName is PublishOption' {
        $params = [pscustomobject]@{
            ParameterSetName='PublishOption'
            PublishOption=@{Repository='r'}
            SkipTestsRequested=$true
            ContinuousIntegrationRequested=$false
            OverrideWarningRequested=$true
        }
        $option = Get-NovaReleasePublishOption -ReleaseParameters $params
        $option.Repository | Should -Be 'r'
        $option.SkipTests | Should -BeTrue
        $option.OverrideWarning | Should -BeTrue
    }

    It 'composes from individual fields for other parameter sets' {
        $params = [pscustomobject]@{
            ParameterSetName='Repository'
            LocalRequested=$true
            Repository='r2'
            ModuleDirectoryPath='/m'
            ApiKey='k'
            SkipTestsRequested=$false
            ContinuousIntegrationRequested=$true
            OverrideWarningRequested=$false
        }
        $option = Get-NovaReleasePublishOption -ReleaseParameters $params
        $option.Local | Should -BeTrue
        $option.Repository | Should -Be 'r2'
        $option.ModuleDirectoryPath | Should -Be '/m'
        $option.ApiKey | Should -Be 'k'
        $option.ContinuousIntegration | Should -BeTrue
    }
}
