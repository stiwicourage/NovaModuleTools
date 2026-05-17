BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaFirstConfiguredValue.ps1')
    . (Join-Path $projectRoot 'src/private/shared/ResolveNovaSecretValue.ps1')

    function Get-NovaEnvironmentVariableValue {param([string]$Name)}
}

Describe 'Get-NovaSecretSourceValue' {
    It 'returns the property value when present' {
        $sources = [pscustomobject]@{Name = 'value'}

        Get-NovaSecretSourceValue -SecretSources $sources -Name 'Name' | Should -Be 'value'
    }

    It 'returns null when the property is missing on a populated source' {
        $sources = [pscustomobject]@{Other = 'x'}

        Get-NovaSecretSourceValue -SecretSources $sources -Name 'Missing' | Should -BeNullOrEmpty
    }
}

Describe 'Resolve-NovaSecretValue' {
    It 'returns ExplicitValue when configured' {
        $sources = [pscustomobject]@{ExplicitValue = 'literal'}

        Resolve-NovaSecretValue -SecretSources $sources | Should -Be 'literal'
    }

    It 'reads the environment variable when an explicit name is set' {
        $sources = [pscustomobject]@{ExplicitEnvironmentVariableName = 'NOVA_TEST_SECRET'}
        Mock Get-NovaEnvironmentVariableValue {return 'env-value'} -ParameterFilter {$Name -eq 'NOVA_TEST_SECRET'}

        Resolve-NovaSecretValue -SecretSources $sources | Should -Be 'env-value'
    }

    It 'falls back to ConfiguredValue when neither explicit value nor env var name is set' {
        $sources = [pscustomobject]@{ConfiguredValue = 'configured'}

        Resolve-NovaSecretValue -SecretSources $sources | Should -Be 'configured'
    }
}
