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

Describe 'Get-NovaModuleSelfUpdateFailureMessage' {
    It 'splits failure details and recovery guidance across separate lines' {
        $message = Get-NovaModuleSelfUpdateFailureMessage -FailureDetail 'gallery offline' -Scope 'CurrentUser'

        $message | Should -Be (@(
            'NovaModuleTools self-update failed: gallery offline'
            'Confirm that the PowerShell Gallery is reachable and that this session can update installed modules, then rerun the self-update command.'
        ) -join [Environment]::NewLine)
    }

    It 'tells all-users installations to rerun the update from an elevated session' {
        $message = Get-NovaModuleSelfUpdateFailureMessage -FailureDetail 'access denied' -Scope 'AllUsers'

        $message | Should -Be (@(
            'NovaModuleTools self-update failed: access denied'
            'Confirm that the PowerShell Gallery is reachable and that this session can update installed modules, then rerun the self-update command.'
            'NovaModuleTools is installed for all users. Rerun Update-NovaModuleTool from an elevated PowerShell session (Run as Administrator on Windows, sudo pwsh on Linux or macOS).'
        ) -join [Environment]::NewLine)
    }
}

Describe 'Invoke-NovaModuleSelfUpdateOrStop' {
    It 'installs the PSModuleUpdate plan of the workflow' {
        Mock Install-NovaPSModuleUpdate {}
        $updatePlan = [pscustomobject]@{ModuleName='Nova'; TargetVersion='2.0.0'}
        Invoke-NovaModuleSelfUpdateOrStop -Plan ([pscustomobject]@{ModuleName='Nova'; Scope='CurrentUser'}) -UpdatePlan $updatePlan
        Assert-MockCalled Install-NovaPSModuleUpdate -Times 1 -ParameterFilter {$UpdatePlan.TargetVersion -eq '2.0.0'}
    }
    It 'wraps update failures in a Nova.Dependency.ModuleSelfUpdateFailed error' {
        Mock Install-NovaPSModuleUpdate {throw 'gallery offline'}
        $thrown = $null
        try {
            Invoke-NovaModuleSelfUpdateOrStop -Plan ([pscustomobject]@{ModuleName='Nova'; Scope='CurrentUser'}) -UpdatePlan ([pscustomobject]@{})
        } catch {
            $thrown = $_
        }

        $thrown | Should -Not -BeNullOrEmpty
        $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Dependency.ModuleSelfUpdateFailed'
        $thrown.Exception.Message | Should -Be (Get-NovaModuleSelfUpdateFailureMessage -FailureDetail 'gallery offline' -Scope 'CurrentUser')
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
        Mock Install-NovaPSModuleUpdate {}
        Mock Get-NovaModuleReleaseNotesUri {throw 'should not run'}
        $plan = [pscustomobject]@{UpdateAvailable=$false; RestartRequired=$false; ModuleName='Nova'; CurrentVersion='1.0.0'; UsedAllowPrerelease=$false; Updated=$false; Cancelled=$false; LookupRepository='PSGallery'; ReleaseNotesUri=$null}
        $result = Invoke-NovaModuleSelfUpdateWorkflow -WorkflowContext ([pscustomobject]@{Plan=$plan; WorkflowParams=@{}}) -ShouldRun:$false
        $result.Updated | Should -BeFalse
        $result.ReleaseNotesUri | Should -BeNull
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {$Text -eq 'NovaModuleTools is already up to date.' -and $color -eq 'Green'}
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {$Text -eq 'Current version: 1.0.0'}
        Should -Invoke Install-NovaPSModuleUpdate -Times 0
    }

    It 'writes a preview summary in WhatIf mode without updating the module' {
        Mock Install-NovaPSModuleUpdate {}
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
        Should -Invoke Install-NovaPSModuleUpdate -Times 0
    }

    It 'writes a cancellation summary when the update is cancelled before execution' {
        Mock Install-NovaPSModuleUpdate {}
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
        Should -Invoke Install-NovaPSModuleUpdate -Times 0
    }

    It 'performs update, sets Updated, resolves release notes, and prints the next step when update is available' {
        Mock Install-NovaPSModuleUpdate {}
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

        $result = Invoke-NovaModuleSelfUpdateWorkflow -WorkflowContext ([pscustomobject]@{Plan=$plan; UpdatePlan=[pscustomobject]@{TargetVersion='1.1.0'}; WorkflowParams=@{}}) -ShouldRun

        $result.Updated | Should -BeTrue
        $result.ReleaseNotesUri | Should -Be 'https://example.com/n'
        Assert-MockCalled Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Installing version 1.1.0' -and $PercentComplete -eq 80
        }
        Assert-MockCalled Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Reading release notes from the updated module' -and $PercentComplete -eq 95
        }
        Assert-MockCalled Write-Progress -Times 1 -ParameterFilter {$Completed}
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {$Text -eq 'Updated NovaModuleTools to version 1.1.0.' -and $color -eq 'Green'}
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {$Text -eq 'Get-NovaProjectInfo -InstalledNovaVersion'}
        Assert-MockCalled Write-Progress -Times 3
        Assert-MockCalled Install-NovaPSModuleUpdate -Times 1 -ParameterFilter {$UpdatePlan.TargetVersion -eq '1.1.0'}
    }

    It 'tells the user to restart when the newer version is already installed' {
        Mock Install-NovaPSModuleUpdate {}
        Mock Get-NovaModuleReleaseNotesUri {throw 'should not run'}
        $plan = [pscustomobject]@{UpdateAvailable=$false; RestartRequired=$true; ModuleName='NovaModuleTools'; CurrentVersion='1.0.0'; LookupCandidateVersion='1.1.0'; Updated=$false; Cancelled=$false; LookupRepository='PSGallery'; ReleaseNotesUri=$null}

        $null = Invoke-NovaModuleSelfUpdateWorkflow -WorkflowContext ([pscustomobject]@{Plan=$plan; WorkflowParams=@{}}) -ShouldRun:$false

        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {$Text -eq 'NovaModuleTools version 1.1.0 is already installed. Restart PowerShell to use it.' -and $color -eq 'Green'}
        Should -Invoke Install-NovaPSModuleUpdate -Times 0
    }
}
