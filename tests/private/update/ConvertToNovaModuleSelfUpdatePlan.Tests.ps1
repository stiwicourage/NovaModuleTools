BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/ConvertToNovaModuleSelfUpdatePlan.ps1')
}

Describe 'ConvertTo-NovaModuleSelfUpdatePlan' {
    BeforeAll {
        $script:installed = [pscustomobject]@{ModuleName = 'NovaModuleTools'; Version = '1.0.0'}

        function New-TestUpdatePlan {
            param([string]$Disposition, [string]$TargetVersion, [bool]$TargetIsPrerelease)
            [pscustomobject]@{
                Disposition = $Disposition
                TargetVersion = $TargetVersion
                TargetIsPrerelease = $TargetIsPrerelease
                RepositoryName = 'PSGallery'
                Scope = 'CurrentUser'
            }
        }
    }

    It 'maps a stable update to an available, non-prerelease Nova plan' {
        $plan = ConvertTo-NovaModuleSelfUpdatePlan -InstalledModule $script:installed -UpdatePlan (New-TestUpdatePlan 'UpdateAvailable' '1.1.0' $false) -PrereleaseNotificationsEnabled $false

        $plan.ModuleName | Should -Be 'NovaModuleTools'
        $plan.CurrentVersion | Should -Be '1.0.0'
        $plan.TargetVersion | Should -Be '1.1.0'
        $plan.LookupCandidateVersion | Should -Be '1.1.0'
        $plan.LookupCandidateChannel | Should -Be 'Stable'
        $plan.LookupRepository | Should -Be 'PSGallery'
        $plan.Scope | Should -Be 'CurrentUser'
        $plan.PrereleaseNotificationsEnabled | Should -BeFalse
        $plan.UpdateAvailable | Should -BeTrue
        $plan.Updated | Should -BeFalse
        $plan.Cancelled | Should -BeFalse
        $plan.RestartRequired | Should -BeFalse
        $plan.IsPrereleaseTarget | Should -BeFalse
        $plan.UsedAllowPrerelease | Should -BeFalse
    }

    It 'flags prerelease targets so the command can request prerelease confirmation' {
        $plan = ConvertTo-NovaModuleSelfUpdatePlan -InstalledModule $script:installed -UpdatePlan (New-TestUpdatePlan 'UpdateAvailable' '2.0.0-beta1' $true) -PrereleaseNotificationsEnabled $true

        $plan.TargetVersion | Should -Be '2.0.0-beta1'
        $plan.LookupCandidateChannel | Should -Be 'Prerelease'
        $plan.IsPrereleaseTarget | Should -BeTrue
        $plan.UsedAllowPrerelease | Should -BeTrue
    }

    It 'maps an up-to-date plan to a plan without a target version' {
        $plan = ConvertTo-NovaModuleSelfUpdatePlan -InstalledModule $script:installed -UpdatePlan (New-TestUpdatePlan 'UpToDate' '1.0.0' $false) -PrereleaseNotificationsEnabled $false

        $plan.UpdateAvailable | Should -BeFalse
        $plan.TargetVersion | Should -BeNullOrEmpty
        $plan.LookupCandidateVersion | Should -Be '1.0.0'
        $plan.IsPrereleaseTarget | Should -BeFalse
        $plan.RestartRequired | Should -BeFalse
    }

    It 'marks an already installed newer version as requiring a restart instead of an update' {
        $plan = ConvertTo-NovaModuleSelfUpdatePlan -InstalledModule $script:installed -UpdatePlan (New-TestUpdatePlan 'AlreadyInstalledRestartRequired' '1.1.0' $false) -PrereleaseNotificationsEnabled $false

        $plan.UpdateAvailable | Should -BeFalse
        $plan.RestartRequired | Should -BeTrue
        $plan.LookupCandidateVersion | Should -Be '1.1.0'
    }
}
