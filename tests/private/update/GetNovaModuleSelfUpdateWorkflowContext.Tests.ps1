BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/GetNovaModuleSelfUpdateWorkflowContext.ps1')
    function Read-NovaUpdateNotificationPreference {[pscustomobject]@{PrereleaseNotificationsEnabled=$false}}
    function Get-NovaInstalledModuleVersionInfo {[pscustomobject]@{Version='1.0.0'}}
    function Invoke-NovaModuleUpdateLookup {param([switch]$AllowPrereleaseNotifications,[int]$TimeoutMilliseconds) [pscustomobject]@{Version='1.1.0'}}
    function Get-NovaModuleSelfUpdatePlan {param($InstalledModule,$LookupResult,$PrereleaseNotificationsEnabled) [pscustomobject]@{TargetVersion='1.1.0'; IsPrereleaseTarget=$false}}
    function Stop-NovaOperation {param([string]$Message,[string]$ErrorId,$Category,$TargetObject) throw [System.Management.Automation.ErrorRecord]::new([System.Exception]::new($Message),$ErrorId,$Category,$TargetObject)}
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

    It 'throws when no lookup result is available' {
        Mock Read-NovaUpdateNotificationPreference {[pscustomobject]@{PrereleaseNotificationsEnabled=$false}}
        Mock Get-NovaInstalledModuleVersionInfo {[pscustomobject]@{Version='1.0.0'}}
        Mock Invoke-NovaModuleUpdateLookup {$null}
        { Get-NovaModuleSelfUpdateWorkflowContext } | Should -Throw -ErrorId 'Nova.Dependency.ModuleSelfUpdateCandidateUnavailable'
    }
}
