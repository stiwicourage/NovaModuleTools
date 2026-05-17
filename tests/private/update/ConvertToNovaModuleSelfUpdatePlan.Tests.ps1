BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/ConvertToNovaModuleSelfUpdatePlan.ps1')
}

Describe 'Get-NovaModuleSelfUpdateLookupCandidate' {
    It 'returns null when the lookup result is null' {
        Get-NovaModuleSelfUpdateLookupCandidate -LookupResult $null -PrereleaseNotificationsEnabled $true | Should -BeNullOrEmpty
    }

    It 'prefers the prerelease candidate when prerelease notifications are enabled' {
        $lookup = [pscustomobject]@{
            Prerelease = [pscustomobject]@{Version = '2.0.0-beta1'}
            Stable = [pscustomobject]@{Version = '1.5.0'}
        }
        (Get-NovaModuleSelfUpdateLookupCandidate -LookupResult $lookup -PrereleaseNotificationsEnabled $true).Version | Should -Be '2.0.0-beta1'
    }

    It 'prefers the stable candidate when prerelease notifications are disabled' {
        $lookup = [pscustomobject]@{
            Prerelease = [pscustomobject]@{Version = '2.0.0-beta1'}
            Stable = [pscustomobject]@{Version = '1.5.0'}
        }
        (Get-NovaModuleSelfUpdateLookupCandidate -LookupResult $lookup -PrereleaseNotificationsEnabled $false).Version | Should -Be '1.5.0'
    }

    It 'falls back to the prerelease candidate when no stable candidate exists and prerelease notifications are disabled' {
        $lookup = [pscustomobject]@{
            Prerelease = [pscustomobject]@{Version = '2.0.0-beta1'}
            Stable = $null
        }
        (Get-NovaModuleSelfUpdateLookupCandidate -LookupResult $lookup -PrereleaseNotificationsEnabled $false).Version | Should -Be '2.0.0-beta1'
    }
}

Describe 'Get-NovaModuleSelfUpdateLookupRepository' {
    It 'returns the candidate repository when the candidate carries one' {
        $candidate = [pscustomobject]@{Repository = 'CandidateRepo'}
        $lookup = [pscustomobject]@{SourceRepository = 'LookupRepo'}
        Get-NovaModuleSelfUpdateLookupRepository -LookupResult $lookup -LookupCandidate $candidate | Should -Be 'CandidateRepo'
    }

    It 'falls back to the lookup result SourceRepository when the candidate lacks Repository' {
        $candidate = [pscustomobject]@{Version = '1.0.0'}
        $lookup = [pscustomobject]@{SourceRepository = 'LookupRepo'}
        Get-NovaModuleSelfUpdateLookupRepository -LookupResult $lookup -LookupCandidate $candidate | Should -Be 'LookupRepo'
    }

    It 'returns null when neither the candidate nor the lookup result carries a repository' {
        $candidate = [pscustomobject]@{Version = '1.0.0'}
        $lookup = [pscustomobject]@{Version = '1.0.0'}
        Get-NovaModuleSelfUpdateLookupRepository -LookupResult $lookup -LookupCandidate $candidate | Should -BeNullOrEmpty
    }
}

Describe 'Get-NovaModuleSelfUpdatePlanContext' {
    It 'returns empty lookup fields when no lookup result is available' {
        $context = Get-NovaModuleSelfUpdatePlanContext -LookupResult $null -PrereleaseNotificationsEnabled $true
        $context.LookupCandidateVersion | Should -BeNullOrEmpty
        $context.LookupCandidateChannel | Should -BeNullOrEmpty
        $context.LookupRepository | Should -BeNullOrEmpty
        $context.PrereleaseNotificationsEnabled | Should -BeTrue
    }

    It 'populates lookup candidate metadata when the lookup result has a stable candidate' {
        $lookup = [pscustomobject]@{
            Prerelease = $null
            Stable = [pscustomobject]@{Version = '1.5.0'; Channel = 'Stable'; Repository = 'PSGallery'}
            SourceRepository = 'PSGallery'
        }
        $context = Get-NovaModuleSelfUpdatePlanContext -LookupResult $lookup -PrereleaseNotificationsEnabled $false

        $context.LookupCandidateVersion | Should -Be '1.5.0'
        $context.LookupCandidateChannel | Should -Be 'Stable'
        $context.LookupRepository | Should -Be 'PSGallery'
    }
}

Describe 'ConvertTo-NovaModuleSelfUpdatePlan' {
    BeforeAll {
        $script:installed = [pscustomobject]@{ModuleName = 'NovaModuleTools'; Version = '1.0.0'}
        $script:context = [pscustomobject]@{
            LookupCandidateVersion = '2.0.0-beta1'
            LookupCandidateChannel = 'Prerelease'
            LookupRepository = 'PSGallery'
            PrereleaseNotificationsEnabled = $true
        }
    }

    It 'returns a no-update plan when no target version is provided' {
        $plan = ConvertTo-NovaModuleSelfUpdatePlan -InstalledModule $script:installed -PlanContext $script:context

        $plan.TargetVersion | Should -BeNullOrEmpty
        $plan.UpdateAvailable | Should -BeFalse
        $plan.IsPrereleaseTarget | Should -BeFalse
        $plan.UsedAllowPrerelease | Should -BeFalse
    }

    It 'marks the plan as an available update when a target version is provided' {
        $plan = ConvertTo-NovaModuleSelfUpdatePlan -InstalledModule $script:installed -PlanContext $script:context -TargetVersion '2.0.0'

        $plan.TargetVersion | Should -Be '2.0.0'
        $plan.UpdateAvailable | Should -BeTrue
        $plan.IsPrereleaseTarget | Should -BeFalse
    }

    It 'flags prerelease target plans through IsPrereleaseTarget and UsedAllowPrerelease' {
        $plan = ConvertTo-NovaModuleSelfUpdatePlan -InstalledModule $script:installed -PlanContext $script:context -TargetVersion '2.0.0-beta1' -PrereleaseTarget

        $plan.IsPrereleaseTarget | Should -BeTrue
        $plan.UsedAllowPrerelease | Should -BeTrue
    }
}
