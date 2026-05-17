BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/GetNovaModuleSelfUpdatePlan.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaModuleSelfUpdatePlan.TestSupport.ps1')
}

Describe 'Get-NovaModuleSelfUpdatePlan' {
    BeforeAll {
        $script:installed = [pscustomobject]@{ModuleName = 'NovaModuleTools'; Version = '1.0.0'; SemanticVersion = [semver]'1.0.0'}
        $script:lookup = [pscustomobject]@{
            Prerelease = [pscustomobject]@{Version = '2.0.0-beta1'}
            Stable = [pscustomobject]@{Version = '2.0.0'}
        }
    }

    It 'targets the prerelease version when a prerelease update is available' {
        Mock Test-NovaPrereleaseUpdateAvailable {return $true}
        Mock Test-NovaStableUpdateAvailable {return $false}

        $plan = Get-NovaModuleSelfUpdatePlan -InstalledModule $script:installed -LookupResult $script:lookup -PrereleaseNotificationsEnabled $true

        $plan.TargetVersion | Should -Be '2.0.0-beta1'
        $plan.IsPrereleaseTarget | Should -BeTrue
    }

    It 'targets the stable version when no prerelease update applies but a stable update is available' {
        Mock Test-NovaPrereleaseUpdateAvailable {return $false}
        Mock Test-NovaStableUpdateAvailable {return $true}

        $plan = Get-NovaModuleSelfUpdatePlan -InstalledModule $script:installed -LookupResult $script:lookup -PrereleaseNotificationsEnabled $false

        $plan.TargetVersion | Should -Be '2.0.0'
        $plan.IsPrereleaseTarget | Should -BeFalse
    }

    It 'returns a no-update plan when no update is available' {
        Mock Test-NovaPrereleaseUpdateAvailable {return $false}
        Mock Test-NovaStableUpdateAvailable {return $false}

        $plan = Get-NovaModuleSelfUpdatePlan -InstalledModule $script:installed -LookupResult $script:lookup -PrereleaseNotificationsEnabled $true

        $plan.UpdateAvailable | Should -BeFalse
    }
}
