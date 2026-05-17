BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageMetadataElement.ps1')
}

Describe 'Get-NovaPackageMetadataElement' {
    It 'returns $null when value is empty' {
        Get-NovaPackageMetadataElement -Name 'id' -Value '' | Should -BeNullOrEmpty
    }

    It 'returns XML element with escaped value' {
        Get-NovaPackageMetadataElement -Name 'id' -Value 'A & B' | Should -Be '    <id>A &amp; B</id>'
    }
}
