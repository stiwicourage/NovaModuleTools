BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/GetNovaModuleSelfUpdatePlan.ps1')

    function Get-NovaModuleSelfUpdatePlanContext {
        param([pscustomobject]$LookupResult, [bool]$PrereleaseNotificationsEnabled)
        return [pscustomobject]@{
            LookupCandidateVersion = $null
            LookupCandidateChannel = $null
            LookupRepository = $null
            PrereleaseNotificationsEnabled = $PrereleaseNotificationsEnabled
        }
    }

    function Get-NovaAvailableSemanticVersion {
        param([object]$VersionInfo)
        if ($null -eq $VersionInfo) {return $null}
        return [semver]$VersionInfo.Version
    }

    function Test-NovaPrereleaseUpdateAvailable {
        param([pscustomobject]$LookupResult, [semver]$InstalledVersion, [semver]$StableVersion, [bool]$PrereleaseNotificationsEnabled)
        return $false
    }

    function Test-NovaStableUpdateAvailable {
        param([semver]$StableVersion, [semver]$InstalledVersion)
        return $false
    }

    function ConvertTo-NovaModuleSelfUpdatePlan {
        param([pscustomobject]$InstalledModule, [pscustomobject]$PlanContext, [string]$TargetVersion, [switch]$PrereleaseTarget)
        return [pscustomobject]@{
            TargetVersion = $TargetVersion
            IsPrereleaseTarget = $PrereleaseTarget.IsPresent
            UpdateAvailable = -not [string]::IsNullOrWhiteSpace($TargetVersion)
        }
    }
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
