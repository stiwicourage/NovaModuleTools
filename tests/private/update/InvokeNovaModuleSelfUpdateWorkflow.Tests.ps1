BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/update/InvokeNovaModuleSelfUpdateWorkflow.ps1')
    . (Join-Path $PSScriptRoot 'InvokeNovaModuleSelfUpdateWorkflow.TestSupport.ps1')
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
        $thrown = $null
        try {
            Invoke-NovaModuleSelfUpdateOrStop -Plan ([pscustomobject]@{ModuleName='Nova'; UsedAllowPrerelease=$false})
        } catch {
            $thrown = $_
        }

        $thrown | Should -Not -BeNullOrEmpty
        $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Dependency.ModuleSelfUpdateFailed'
        $thrown.Exception.Message | Should -Be 'NovaModuleTools self-update failed: gallery offline Confirm that the PowerShell Gallery is reachable and that this session can update installed modules, then rerun Update-NovaModuleTool.'
    }
}

Describe 'Get-NovaModuleSelfUpdateWorkflowUpdateStatus' {
    It 'describes prerelease installs explicitly' {
        $workflowContext = [pscustomobject]@{
            Plan = [pscustomobject]@{
                IsPrereleaseTarget = $true
                TargetVersion = '1.2.0-preview1'
            }
        }

        Get-NovaModuleSelfUpdateWorkflowUpdateStatus -WorkflowContext $workflowContext | Should -Be 'Installing prerelease version 1.2.0-preview1'
    }
}

Describe 'Get-NovaModuleSelfUpdateWorkflowRepositoryLine' {
    It 'returns null when the repository name is blank' {
        Get-NovaModuleSelfUpdateWorkflowRepositoryLine -Result ([pscustomobject]@{LookupRepository = ''}) | Should -BeNullOrEmpty
    }
}

Describe 'Invoke-NovaModuleSelfUpdateWorkflow' {
    BeforeEach {
        Mock Write-Message {}
        Mock Write-Progress {}
    }

    It 'returns plan with null release notes when no update is available' {
        Mock Invoke-NovaModuleSelfUpdate {}
        Mock Get-NovaModuleReleaseNotesUri {throw 'should not run'}
        $plan = [pscustomobject]@{UpdateAvailable=$false; ModuleName='Nova'; CurrentVersion='1.0.0'; UsedAllowPrerelease=$false; Updated=$false; Cancelled=$false; LookupRepository='PSGallery'; ReleaseNotesUri=$null}
        $result = Invoke-NovaModuleSelfUpdateWorkflow -WorkflowContext ([pscustomobject]@{Plan=$plan; WorkflowParams=@{}}) -ShouldRun:$false
        $result.Updated | Should -BeFalse
        $result.ReleaseNotesUri | Should -BeNull
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {$Text -eq 'NovaModuleTools is already up to date.' -and $color -eq 'Green'}
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {$Text -eq 'Current version: 1.0.0'}
        Should -Invoke Invoke-NovaModuleSelfUpdate -Times 0
    }

    It 'writes a preview summary in WhatIf mode without updating the module' {
        Mock Invoke-NovaModuleSelfUpdate {}
        Mock Get-NovaModuleReleaseNotesUri {throw 'should not run'}
        $plan = [pscustomobject]@{
            UpdateAvailable = $true
            IsPrereleaseTarget = $false
            ModuleName = 'NovaModuleTools'
            CurrentVersion = '1.0.0'
            TargetVersion = '1.1.0'
            UsedAllowPrerelease = $false
            Updated = $false
            Cancelled = $false
            LookupRepository = 'PSGallery'
            ReleaseNotesUri = $null
        }

        $result = Invoke-NovaModuleSelfUpdateWorkflow -WorkflowContext ([pscustomobject]@{Plan=$plan; WorkflowParams=@{WhatIf=$true}}) -ShouldRun:$false

        $result.ReleaseNotesUri | Should -BeNull
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {$Text -eq 'Self-update plan ready for NovaModuleTools' -and $color -eq 'Green'}
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {$Text -eq 'Target version: 1.1.0'}
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {$Text -eq 'Repository: PSGallery'}
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {$Text -eq 'Run Update-NovaModuleTool without -WhatIf when you are ready to install version 1.1.0.'}
        Should -Invoke Invoke-NovaModuleSelfUpdate -Times 0
    }

    It 'writes a cancellation summary when the update is cancelled before execution' {
        Mock Invoke-NovaModuleSelfUpdate {}
        $plan = [pscustomobject]@{
            UpdateAvailable = $true
            IsPrereleaseTarget = $false
            ModuleName = 'NovaModuleTools'
            CurrentVersion = '1.0.0'
            TargetVersion = '1.1.0'
            UsedAllowPrerelease = $false
            Updated = $false
            Cancelled = $true
            LookupRepository = 'PSGallery'
            ReleaseNotesUri = $null
        }

        $result = Invoke-NovaModuleSelfUpdateWorkflow -WorkflowContext ([pscustomobject]@{Plan=$plan; WorkflowParams=@{}}) -ShouldRun:$false

        $result.Cancelled | Should -BeTrue
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {$Text -eq 'Self-update cancelled for NovaModuleTools.' -and $color -eq 'Blue'}
        Should -Invoke Invoke-NovaModuleSelfUpdate -Times 0
    }

    It 'performs update, sets Updated, resolves release notes, and prints the next step when update is available' {
        Mock Invoke-NovaModuleSelfUpdate {}
        Mock Get-NovaModuleReleaseNotesUri {'https://example.com/n'}
        $plan = [pscustomobject]@{
            UpdateAvailable = $true
            IsPrereleaseTarget = $false
            ModuleName = 'NovaModuleTools'
            CurrentVersion = '1.0.0'
            TargetVersion = '1.1.0'
            UsedAllowPrerelease = $false
            Updated = $false
            Cancelled = $false
            LookupRepository = 'PSGallery'
            ReleaseNotesUri = $null
        }

        $result = Invoke-NovaModuleSelfUpdateWorkflow -WorkflowContext ([pscustomobject]@{Plan=$plan; WorkflowParams=@{}}) -ShouldRun

        $result.Updated | Should -BeTrue
        $result.ReleaseNotesUri | Should -Be 'https://example.com/n'
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {$Text -eq 'Updated NovaModuleTools to version 1.1.0.' -and $color -eq 'Green'}
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {$Text -eq 'Get-NovaProjectInfo -Installed'}
        Assert-MockCalled Write-Progress -Times 3
    }
}
