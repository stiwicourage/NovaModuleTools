BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaManifestValue.ps1')
}

Describe 'Get-NovaManifestValue' {
    It 'returns dictionary entry by key' {
        Get-NovaManifestValue -Manifest @{Tags='a'} -Name 'Tags' | Should -Be 'a'
    }

    It 'returns object property by name' {
        Get-NovaManifestValue -Manifest ([pscustomobject]@{Tags='b'}) -Name 'Tags' | Should -Be 'b'
    }

    It 'returns $null when the property is missing on an object' {
        Get-NovaManifestValue -Manifest ([pscustomobject]@{Other='x'}) -Name 'Tags' | Should -BeNullOrEmpty
    }
}
