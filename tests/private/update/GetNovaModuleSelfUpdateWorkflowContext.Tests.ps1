BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/GetNovaModuleSelfUpdateWorkflowContext.ps1')
    . (Join-Path $PSScriptRoot 'GetNovaModuleSelfUpdateWorkflowContext.TestSupport.ps1')
}

Describe 'Get-NovaModuleSelfUpdateWorkflowContext' {
    It 'resolves preference, installed module, and lookup result from collaborators' {
        Mock Read-NovaUpdateNotificationPreference {[pscustomobject]@{PrereleaseNotificationsEnabled=$false}}
        Mock Get-NovaInstalledModuleVersionInfo {[pscustomobject]@{Version='1.0.0'}}
        Mock Invoke-NovaModuleUpdateLookup {[pscustomobject]@{Version='2.0.0'}}
        Mock Get-NovaModuleSelfUpdatePlan {[pscustomobject]@{TargetVersion='2.0.0'; IsPrereleaseTarget=$false}}
        $ctx = Get-NovaModuleSelfUpdateWorkflowContext
        $ctx.LookupResult.Version | Should -Be '2.0.0'
        $ctx.Plan.TargetVersion | Should -Be '2.0.0'
        $ctx.Action | Should -Be 'Update NovaModuleTools to version 2.0.0'
    }

    It 'uses supplied preference / installed module / lookup result without calling collaborators' {
        Mock Read-NovaUpdateNotificationPreference {throw 'should not be called'}
        Mock Get-NovaInstalledModuleVersionInfo {throw 'should not be called'}
        Mock Invoke-NovaModuleUpdateLookup {throw 'should not be called'}
        Mock Get-NovaModuleSelfUpdatePlan {[pscustomobject]@{TargetVersion='3.0.0-rc1'; IsPrereleaseTarget=$true}}
        $ctx = Get-NovaModuleSelfUpdateWorkflowContext `
            -Preference ([pscustomobject]@{PrereleaseNotificationsEnabled=$true}) `
            -InstalledModule ([pscustomobject]@{Version='2.5.0'}) `
            -LookupResult ([pscustomobject]@{Version='3.0.0-rc1'})
        $ctx.Action | Should -Be 'Update NovaModuleTools to prerelease version 3.0.0-rc1'
    }

    It 'carries forwarded workflow parameters into the context' {
        Mock Read-NovaUpdateNotificationPreference {[pscustomobject]@{PrereleaseNotificationsEnabled=$false}}
        Mock Get-NovaInstalledModuleVersionInfo {[pscustomobject]@{Version='1.0.0'}}
        Mock Invoke-NovaModuleUpdateLookup {[pscustomobject]@{Version='2.0.0'}}
        Mock Get-NovaModuleSelfUpdatePlan {[pscustomobject]@{TargetVersion='2.0.0'; IsPrereleaseTarget=$false}}

        $ctx = Get-NovaModuleSelfUpdateWorkflowContext -WorkflowParams @{WhatIf = $true}

        $ctx.WorkflowParams.WhatIf | Should -BeTrue
    }

    It 'throws when no lookup result is available' {
        Mock Read-NovaUpdateNotificationPreference {[pscustomobject]@{PrereleaseNotificationsEnabled=$false}}
        Mock Get-NovaInstalledModuleVersionInfo {[pscustomobject]@{Version='1.0.0'}}
        Mock Invoke-NovaModuleUpdateLookup {$null}
        { Get-NovaModuleSelfUpdateWorkflowContext } | Should -Throw -ErrorId 'Nova.Dependency.ModuleSelfUpdateCandidateUnavailable'
    }
}
