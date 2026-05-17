BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageSettingValue.ps1')
}

Describe 'Get-NovaPackageSettingValue' {
    It 'returns $null for null input' {
        Get-NovaPackageSettingValue -InputObject $null -Name 'X' | Should -BeNullOrEmpty
    }

    It 'reads dictionary entries by key' {
        Get-NovaPackageSettingValue -InputObject @{X=1} -Name 'X' | Should -Be 1
    }

    It 'returns $null for missing dictionary keys' {
        Get-NovaPackageSettingValue -InputObject @{} -Name 'X' | Should -BeNullOrEmpty
    }

    It 'reads object property by name' {
        Get-NovaPackageSettingValue -InputObject ([pscustomobject]@{X=2}) -Name 'X' | Should -Be 2
    }

    It 'returns $null when property does not exist' {
        Get-NovaPackageSettingValue -InputObject ([pscustomobject]@{Y=1}) -Name 'X' | Should -BeNullOrEmpty
    }
}
