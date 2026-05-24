BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/InvokeNovaVersionUpdateWorkflow.ps1')

    function Set-NovaModuleVersion {param($ProjectInfo, $Label, [switch]$PreviewRelease, [switch]$Confirm) return [pscustomobject]@{Applied=$true}}
}

Describe 'Invoke-NovaVersionUpdateWorkflowStep' {
    It 'reports progress before invoking the action' {
        Mock Write-Progress {}
        $result = Invoke-NovaVersionUpdateWorkflowStep -Activity 'Updating' -Status 'Writing version' -PercentComplete 80 -Action { 'done' }
        $result | Should -Be 'done'
        Should -Invoke Write-Progress -Times 1 -ParameterFilter { $Activity -eq 'Updating' -and $Status -eq 'Writing version' -and $PercentComplete -eq 80 }
    }
}

Describe 'Get-NovaVersionUpdateEffectiveLabel' {
    It 'prefers EffectiveLabel when present and non-empty' {
        Get-NovaVersionUpdateEffectiveLabel -WorkflowContext ([pscustomobject]@{Label='Patch'; EffectiveLabel='Minor'}) | Should -Be 'Minor'
    }

    It 'falls back to Label when EffectiveLabel is missing' {
        Get-NovaVersionUpdateEffectiveLabel -WorkflowContext ([pscustomobject]@{Label='Patch'}) | Should -Be 'Patch'
    }
}

Describe 'Get-NovaVersionUpdateAdvisoryMessage' {
    It 'returns $null when AdvisoryMessage is missing' {
        Get-NovaVersionUpdateAdvisoryMessage -WorkflowContext ([pscustomobject]@{Other=1}) | Should -BeNullOrEmpty
    }

    It 'returns the message when present' {
        Get-NovaVersionUpdateAdvisoryMessage -WorkflowContext ([pscustomobject]@{AdvisoryMessage='hi'}) | Should -Be 'hi'
    }
}

Describe 'Get-NovaVersionUpdateResult' {
    It 'assembles a structured result' {
        $ctx = [pscustomobject]@{
            PreviousVersion = '1.0.0'
            NewVersion = '1.0.1'
            Label = 'Patch'
            CommitCount = 2
            ProjectInfo = [pscustomobject]@{ProjectJSON='/p/project.json'}
        }
        $result = Get-NovaVersionUpdateResult -WorkflowContext $ctx -Applied -Previewed
        $result.PreviousVersion | Should -Be '1.0.0'
        $result.NewVersion | Should -Be '1.0.1'
        $result.Label | Should -Be 'Patch'
        $result.EffectiveLabel | Should -Be 'Patch'
        $result.CommitCount | Should -Be 2
        $result.ProjectFile | Should -Be '/p/project.json'
        $result.Target | Should -Be 'project.json'
        $result.Applied | Should -BeTrue
        $result.Previewed | Should -BeTrue
    }
}

Describe 'Invoke-NovaVersionUpdateWorkflow' {
    It 'returns a cancelled result when confirmation is declined before the write step' {
        $ctx = [pscustomobject]@{ProjectInfo=[pscustomobject]@{}; PreviewRelease=$false; Label='Patch'; EffectiveLabel='Patch'}
        $result = Invoke-NovaVersionUpdateWorkflow -WorkflowContext $ctx
        $result.Applied | Should -BeFalse
        $result.Cancelled | Should -BeTrue
    }

    It 'returns a result with Applied=true when ShouldRun and the write succeeds' {
        Mock Set-NovaModuleVersion {[pscustomobject]@{Applied=$true}}
        Mock Write-Progress {}
        $ctx = [pscustomobject]@{ProjectInfo=[pscustomobject]@{ProjectJSON='/p/project.json'}; PreviewRelease=$false; Label='Patch'; EffectiveLabel='Patch'; PreviousVersion='1.0.0'; NewVersion='1.0.1'; CommitCount=1}
        $r = Invoke-NovaVersionUpdateWorkflow -WorkflowContext $ctx -ShouldRun
        $r.Applied | Should -BeTrue
        Should -Invoke Write-Progress -Times 1 -ParameterFilter { $Status -eq 'Writing version 1.0.1 to project.json' }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter { $Completed }
    }

    It 'returns a result with Applied=false in WhatIf mode without invoking the writer' {
        Mock Set-NovaModuleVersion {throw 'should not be called'}
        $ctx = [pscustomobject]@{ProjectInfo=[pscustomobject]@{}; PreviewRelease=$false; Label='Patch'; EffectiveLabel='Patch'; PreviousVersion='1.0.0'; NewVersion='1.0.1'; CommitCount=0}
        $r = Invoke-NovaVersionUpdateWorkflow -WorkflowContext $ctx -WhatIfEnabled
        $r.Applied | Should -BeFalse
        $r.Previewed | Should -BeTrue
    }
}
