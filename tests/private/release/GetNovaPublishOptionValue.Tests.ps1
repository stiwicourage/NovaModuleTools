BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/GetNovaPublishOptionValue.ps1')
}

Describe 'Get-NovaPublishOptionValue' {
    It 'returns the value when the option key exists' {
        Get-NovaPublishOptionValue -PublishOption @{Repository = 'r'} -Name 'Repository' | Should -Be 'r'
    }

    It 'returns $null when the option key is absent' {
        Get-NovaPublishOptionValue -PublishOption @{} -Name 'Repository' | Should -BeNullOrEmpty
    }
}
