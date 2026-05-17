BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/TestNovaPrereleaseUpdateAvailable.ps1')
}

Describe 'Test-NovaPrereleaseUpdateAvailable' {
    BeforeAll {
        $script:lookupWithPrereleaseOnly = [pscustomobject]@{
            Prerelease = [pscustomobject]@{Version = '2.0.0-beta1'}
            Stable = $null
        }
        $script:lookupWithMatchingStable = [pscustomobject]@{
            Prerelease = [pscustomobject]@{Version = '2.0.0'}
            Stable = [pscustomobject]@{Version = '2.0.0'}
        }
        $script:lookupWithDistinctPrerelease = [pscustomobject]@{
            Prerelease = [pscustomobject]@{Version = '2.1.0-rc1'}
            Stable = [pscustomobject]@{Version = '2.0.0'}
        }
    }

    It 'returns false when prerelease notifications are disabled' {
        Test-NovaPrereleaseUpdateAvailable -LookupResult $script:lookupWithPrereleaseOnly -InstalledVersion ([semver]'1.0.0') -PrereleaseNotificationsEnabled $false | Should -BeFalse
    }

    It 'returns false when the lookup has no prerelease candidate' {
        $lookup = [pscustomobject]@{Prerelease = $null; Stable = [pscustomobject]@{Version = '2.0.0'}}
        Test-NovaPrereleaseUpdateAvailable -LookupResult $lookup -InstalledVersion ([semver]'1.0.0') -PrereleaseNotificationsEnabled $true | Should -BeFalse
    }

    It 'returns false when the prerelease version is not greater than the installed version' {
        Test-NovaPrereleaseUpdateAvailable -LookupResult $script:lookupWithPrereleaseOnly -InstalledVersion ([semver]'2.0.0') -PrereleaseNotificationsEnabled $true | Should -BeFalse
    }

    It 'returns true when no stable candidate is present and the prerelease is newer' {
        Test-NovaPrereleaseUpdateAvailable -LookupResult $script:lookupWithPrereleaseOnly -InstalledVersion ([semver]'1.0.0') -PrereleaseNotificationsEnabled $true | Should -BeTrue
    }

    It 'returns false when the prerelease version matches the stable version' {
        Test-NovaPrereleaseUpdateAvailable -LookupResult $script:lookupWithMatchingStable -InstalledVersion ([semver]'1.0.0') -StableVersion ([semver]'2.0.0') -PrereleaseNotificationsEnabled $true | Should -BeFalse
    }

    It 'returns true when prerelease and stable target different versions' {
        Test-NovaPrereleaseUpdateAvailable -LookupResult $script:lookupWithDistinctPrerelease -InstalledVersion ([semver]'2.0.0') -StableVersion ([semver]'2.0.0') -PrereleaseNotificationsEnabled $true | Should -BeTrue
    }
}
