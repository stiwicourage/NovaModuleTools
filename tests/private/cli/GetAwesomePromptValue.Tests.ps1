BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/cli/GetAwesomePromptValue.ps1')
}

Describe 'Get-AwesomePromptValue' {
    It 'returns hashtable entry by name' {
        Get-AwesomePromptValue -Ask @{Default = 'd'} -Name 'Default' | Should -Be 'd'
    }

    It 'returns $null for missing hashtable entries' {
        Get-AwesomePromptValue -Ask @{Default = 'd'} -Name 'Missing' | Should -BeNullOrEmpty
    }

    It 'returns object property values by name' {
        $ask = [pscustomobject]@{Default = 'p'}
        Get-AwesomePromptValue -Ask $ask -Name 'Default' | Should -Be 'p'
    }

    It 'returns $null for missing object properties' {
        $ask = [pscustomobject]@{Default = 'p'}
        Get-AwesomePromptValue -Ask $ask -Name 'Missing' | Should -BeNullOrEmpty
    }
}
