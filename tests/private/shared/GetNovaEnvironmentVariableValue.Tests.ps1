BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaEnvironmentVariableValue.ps1')
}

Describe 'Get-NovaEnvironmentVariableValue' {
    It 'returns the environment variable value when set' {
        $name = "NOVA_TEST_$( [Guid]::NewGuid().ToString('N') )"
        [System.Environment]::SetEnvironmentVariable($name, 'value', 'Process')
        try {
            Get-NovaEnvironmentVariableValue -Name $name | Should -Be 'value'
        } finally {
            [System.Environment]::SetEnvironmentVariable($name, $null, 'Process')
        }
    }

    It 'returns $null for whitespace name input' {
        Get-NovaEnvironmentVariableValue -Name ' ' | Should -BeNullOrEmpty
    }

    It 'returns $null for empty name input' {
        Get-NovaEnvironmentVariableValue -Name '' | Should -BeNullOrEmpty
    }

    It 'trims surrounding whitespace from the name before lookup' {
        $name = "NOVA_TEST_$( [Guid]::NewGuid().ToString('N') )"
        [System.Environment]::SetEnvironmentVariable($name, 'trimmed', 'Process')
        try {
            Get-NovaEnvironmentVariableValue -Name " $name " | Should -Be 'trimmed'
        } finally {
            [System.Environment]::SetEnvironmentVariable($name, $null, 'Process')
        }
    }
}
