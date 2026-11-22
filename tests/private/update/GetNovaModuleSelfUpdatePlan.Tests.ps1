BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/GetNovaModuleSelfUpdatePlan.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaModuleSelfUpdatePlan.TestSupport.ps1')
}

Describe 'Get-NovaModuleSelfUpdatePlan' {
    BeforeAll {
        $script:installed = [pscustomobject]@{ModuleName = 'NovaModuleTools'; Version = '1.0.0'}
    }

    It 'converts the PSModuleUpdate plan for the supported <Disposition> disposition' -ForEach @(
        @{Disposition = 'UpdateAvailable'}
        @{Disposition = 'UpToDate'}
        @{Disposition = 'AlreadyInstalledRestartRequired'}
    ) {
        Mock ConvertTo-NovaModuleSelfUpdatePlan {[pscustomobject]@{Disposition = $UpdatePlan.Disposition}}

        $plan = Get-NovaModuleSelfUpdatePlan -InstalledModule $script:installed -UpdatePlan ([pscustomobject]@{Disposition = $Disposition}) -PrereleaseNotificationsEnabled $true

        $plan.Disposition | Should -Be $Disposition
        Should -Invoke ConvertTo-NovaModuleSelfUpdatePlan -Times 1 -ParameterFilter {$InstalledModule.Version -eq '1.0.0' -and $PrereleaseNotificationsEnabled}
    }

    It 'stops instead of guessing when PSModuleUpdate returns an unsupported disposition' {
        $updatePlan = [pscustomobject]@{Disposition = 'Downgrade'}

        {Get-NovaModuleSelfUpdatePlan -InstalledModule $script:installed -UpdatePlan $updatePlan -PrereleaseNotificationsEnabled $false} |
                Should -Throw -ErrorId 'Nova.Dependency.ModuleSelfUpdateCandidateUnavailable' -ExpectedMessage "*unsupported update disposition 'Downgrade'*"
    }
}
