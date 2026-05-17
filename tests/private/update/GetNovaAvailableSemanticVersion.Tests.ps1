BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/GetNovaAvailableSemanticVersion.ps1')
}

Describe 'Get-NovaAvailableSemanticVersion' {
    It 'returns null when the version info is null' {
        Get-NovaAvailableSemanticVersion -VersionInfo $null | Should -BeNullOrEmpty
    }

    It 'returns the semantic version parsed from the version info' {
        $info = [pscustomobject]@{Version = '1.2.3'}
        $result = Get-NovaAvailableSemanticVersion -VersionInfo $info
        $result | Should -BeOfType ([semver])
        $result | Should -Be ([semver]'1.2.3')
    }

    It 'preserves prerelease labels' {
        $info = [pscustomobject]@{Version = '2.0.0-beta1'}
        Get-NovaAvailableSemanticVersion -VersionInfo $info | Should -Be ([semver]'2.0.0-beta1')
    }
}
