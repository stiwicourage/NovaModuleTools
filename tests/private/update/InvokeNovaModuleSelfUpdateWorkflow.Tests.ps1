BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/InvokeNovaModuleSelfUpdateWorkflow.ps1')
    function Invoke-NovaModuleSelfUpdate {param([string]$ModuleName,[switch]$AllowPrerelease)}
    function Get-NovaModuleReleaseNotesUri {'https://example.com/notes'}
    function Stop-NovaOperation {param([string]$Message,[string]$ErrorId,$Category,$TargetObject) throw [System.Management.Automation.ErrorRecord]::new([System.Exception]::new($Message),$ErrorId,$Category,$TargetObject)}
}

Describe 'Complete-NovaModuleSelfUpdateResult' {
    It 'sets existing ReleaseNotesUri property when present' {
        $plan = [pscustomobject]@{ReleaseNotesUri='old'}
        $result = Complete-NovaModuleSelfUpdateResult -Plan $plan -ReleaseNotesUri 'new'
        $result.ReleaseNotesUri | Should -Be 'new'
    }
    It 'adds ReleaseNotesUri note property when missing' {
        $plan = [pscustomobject]@{Other='x'}
        $result = Complete-NovaModuleSelfUpdateResult -Plan $plan -ReleaseNotesUri 'u'
        $result.ReleaseNotesUri | Should -Be 'u'
    }
    It 'accepts a null ReleaseNotesUri' {
        $plan = [pscustomobject]@{ReleaseNotesUri='old'}
        $result = Complete-NovaModuleSelfUpdateResult -Plan $plan -ReleaseNotesUri $null
        $result.ReleaseNotesUri | Should -BeNull
    }
}

Describe 'Invoke-NovaModuleSelfUpdateOrStop' {
    It 'calls Invoke-NovaModuleSelfUpdate with module name and prerelease flag' {
        Mock Invoke-NovaModuleSelfUpdate {}
        Invoke-NovaModuleSelfUpdateOrStop -Plan ([pscustomobject]@{ModuleName='Nova'; UsedAllowPrerelease=$true})
        Assert-MockCalled Invoke-NovaModuleSelfUpdate -Times 1 -ParameterFilter {$ModuleName -eq 'Nova' -and $AllowPrerelease}
    }
    It 'wraps update failures in a Nova.Dependency.ModuleSelfUpdateFailed error' {
        Mock Invoke-NovaModuleSelfUpdate {throw 'gallery offline'}
        { Invoke-NovaModuleSelfUpdateOrStop -Plan ([pscustomobject]@{ModuleName='Nova'; UsedAllowPrerelease=$false}) } | Should -Throw -ErrorId 'Nova.Dependency.ModuleSelfUpdateFailed'
    }
}

Describe 'Invoke-NovaModuleSelfUpdateWorkflow' {
    It 'returns plan with null release notes when no update is available' {
        Mock Invoke-NovaModuleSelfUpdate {}
        Mock Get-NovaModuleReleaseNotesUri {throw 'should not run'}
        $plan = [pscustomobject]@{UpdateAvailable=$false; ModuleName='Nova'; UsedAllowPrerelease=$false; Updated=$false; ReleaseNotesUri=$null}
        $result = Invoke-NovaModuleSelfUpdateWorkflow -WorkflowContext ([pscustomobject]@{Plan=$plan})
        $result.Updated | Should -BeFalse
        $result.ReleaseNotesUri | Should -BeNull
    }

    It 'performs update, sets Updated, and resolves release notes when update is available' {
        Mock Invoke-NovaModuleSelfUpdate {}
        Mock Get-NovaModuleReleaseNotesUri {'https://example.com/n'}
        $plan = [pscustomobject]@{UpdateAvailable=$true; ModuleName='Nova'; UsedAllowPrerelease=$false; Updated=$false; ReleaseNotesUri=$null}
        $result = Invoke-NovaModuleSelfUpdateWorkflow -WorkflowContext ([pscustomobject]@{Plan=$plan})
        $result.Updated | Should -BeTrue
        $result.ReleaseNotesUri | Should -Be 'https://example.com/n'
    }
}
