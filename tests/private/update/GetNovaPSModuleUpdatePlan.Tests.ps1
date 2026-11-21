BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/GetNovaPSModuleUpdatePlan.ps1')

    function Get-PSModuleUpdate {param($Module, [string]$Repository, [hashtable]$Policy)}
    function Get-NovaModuleInstallScope {param([string]$ModuleBase) 'CurrentUser'}
    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw [System.Management.Automation.ErrorRecord]::new([System.Exception]::new($Message), $ErrorId, $Category, $TargetObject)}
}

Describe 'Get-NovaPSModuleUpdatePlan' {
    BeforeAll {
        $script:module = [pscustomobject]@{Name = 'NovaModuleTools'; ModuleBase = 'modules/NovaModuleTools/1.0.0'}
    }

    It 'plans a stable PSGallery update in the scope of the installed module' {
        Mock Get-NovaModuleInstallScope {'AllUsers'}
        Mock Get-PSModuleUpdate {[pscustomobject]@{Disposition = 'UpToDate'}}

        $plan = Get-NovaPSModuleUpdatePlan -Module $script:module -PrereleaseNotificationsEnabled $false

        $plan.Disposition | Should -Be 'UpToDate'
        Should -Invoke Get-NovaModuleInstallScope -Times 1 -ParameterFilter {$ModuleBase -eq 'modules/NovaModuleTools/1.0.0'}
        Should -Invoke Get-PSModuleUpdate -Times 1 -ParameterFilter {
            $Module.Name -eq 'NovaModuleTools' -and $Repository -eq 'PSGallery' -and
                    $Policy.Channel -eq 'Stable' -and $Policy.Scope -eq 'AllUsers' -and $Policy.Count -eq 2
        }
    }

    It 'includes prereleases when prerelease notifications are enabled' {
        Mock Get-PSModuleUpdate {[pscustomobject]@{Disposition = 'UpdateAvailable'}}

        $null = Get-NovaPSModuleUpdatePlan -Module $script:module -PrereleaseNotificationsEnabled $true

        Should -Invoke Get-PSModuleUpdate -Times 1 -ParameterFilter {$Policy.Channel -eq 'IncludePrerelease' -and $Policy.Scope -eq 'CurrentUser'}
    }

    It 'stops with the candidate-unavailable error and the PSModuleUpdate detail when planning fails' {
        Mock Get-PSModuleUpdate {throw 'The selected installation has no native provider metadata.'}

        {Get-NovaPSModuleUpdatePlan -Module $script:module -PrereleaseNotificationsEnabled $false} |
                Should -Throw -ErrorId 'Nova.Dependency.ModuleSelfUpdateCandidateUnavailable' -ExpectedMessage 'Unable to determine a NovaModuleTools update candidate.*no native provider metadata*installed from the PowerShell Gallery*'
    }
}
