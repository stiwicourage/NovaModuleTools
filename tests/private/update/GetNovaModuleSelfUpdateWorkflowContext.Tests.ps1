BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/GetNovaModuleSelfUpdateWorkflowContext.ps1')
    . (Join-Path $PSScriptRoot 'GetNovaModuleSelfUpdateWorkflowContext.TestSupport.ps1')
}

Describe 'Get-NovaModuleSelfUpdateWorkflowContext' {
    It 'plans the update for the loaded module through PSModuleUpdate using the prerelease preference' {
        Mock Read-NovaUpdateNotificationPreference {[pscustomobject]@{PrereleaseNotificationsEnabled=$true}}
        Mock Get-NovaInstalledModuleVersionInfo {[pscustomobject]@{Version='1.0.0'; Module=[pscustomobject]@{Name='NovaModuleTools'}}}
        Mock Get-NovaPSModuleUpdatePlan {[pscustomobject]@{Disposition='UpdateAvailable'; TargetVersion='2.0.0'}}
        Mock Get-NovaModuleSelfUpdatePlan {[pscustomobject]@{TargetVersion='2.0.0'; IsPrereleaseTarget=$false}}

        $ctx = Get-NovaModuleSelfUpdateWorkflowContext

        $ctx.UpdatePlan.TargetVersion | Should -Be '2.0.0'
        $ctx.Plan.TargetVersion | Should -Be '2.0.0'
        $ctx.Action | Should -Be 'Update NovaModuleTools to version 2.0.0'
        Should -Invoke Get-NovaPSModuleUpdatePlan -Times 1 -ParameterFilter {$Module.Name -eq 'NovaModuleTools' -and $PrereleaseNotificationsEnabled}
        Should -Invoke Get-NovaModuleSelfUpdatePlan -Times 1 -ParameterFilter {$UpdatePlan.TargetVersion -eq '2.0.0' -and $PrereleaseNotificationsEnabled}
    }

    It 'uses supplied preference / installed module / update plan without calling collaborators' {
        Mock Read-NovaUpdateNotificationPreference {throw 'should not be called'}
        Mock Get-NovaInstalledModuleVersionInfo {throw 'should not be called'}
        Mock Get-NovaPSModuleUpdatePlan {throw 'should not be called'}
        Mock Get-NovaModuleSelfUpdatePlan {[pscustomobject]@{TargetVersion='3.0.0-rc1'; IsPrereleaseTarget=$true}}
        $ctx = Get-NovaModuleSelfUpdateWorkflowContext `
            -Preference ([pscustomobject]@{PrereleaseNotificationsEnabled=$true}) `
            -InstalledModule ([pscustomobject]@{Version='2.5.0'}) `
            -UpdatePlan ([pscustomobject]@{TargetVersion='3.0.0-rc1'})
        $ctx.Action | Should -Be 'Update NovaModuleTools to prerelease version 3.0.0-rc1'
    }

    It 'carries forwarded workflow parameters into the context' {
        $ctx = Get-NovaModuleSelfUpdateWorkflowContext -WorkflowParams @{WhatIf = $true}

        $ctx.WorkflowParams.WhatIf | Should -BeTrue
    }
}
