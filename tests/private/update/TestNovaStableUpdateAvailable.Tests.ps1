BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/TestNovaStableUpdateAvailable.ps1')
}

Describe 'Test-NovaStableUpdateAvailable' {
    It 'returns true when the stable candidate is greater than the installed version' {
        Test-NovaStableUpdateAvailable -StableVersion ([semver]'2.0.0') -InstalledVersion ([semver]'1.0.0') | Should -BeTrue
    }

    It 'returns false when the stable candidate equals the installed version' {
        Test-NovaStableUpdateAvailable -StableVersion ([semver]'1.0.0') -InstalledVersion ([semver]'1.0.0') | Should -BeFalse
    }

    It 'returns false when the stable candidate is older than the installed version' {
        Test-NovaStableUpdateAvailable -StableVersion ([semver]'0.9.0') -InstalledVersion ([semver]'1.0.0') | Should -BeFalse
    }

    It 'returns false when no stable candidate is provided' {
        Test-NovaStableUpdateAvailable -StableVersion $null -InstalledVersion ([semver]'1.0.0') | Should -BeFalse
    }
}
