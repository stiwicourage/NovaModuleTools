BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/InvokeNovaAgenticCopilotScaffoldWorkflow.ps1')

    function Initialize-NovaModuleAgenticCopilotScaffold {
        param(
            [hashtable]$Answer,
            [string]$ProjectRoot,
            [switch]$Example,
            [AllowNull()][pscustomobject]$ScaffoldPolicy
        )
    }

    function Stop-NovaOperation {
        param([string]$Message, [string]$ErrorId, [System.Management.Automation.ErrorCategory]$Category, $TargetObject)
        $exception = [System.Exception]::new($Message)
        $record = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
        throw $record
    }
}

Describe 'Get-NovaAgenticCopilotScaffoldWarningMessage' {
    It 'lists overwrite and add-only paths' {
        $message = Get-NovaAgenticCopilotScaffoldWarningMessage -WorkflowContext ([pscustomobject]@{
            ProjectRoot = '/repo'
            ManagedOverwritePathList = @('.github/agents/', 'AGENTS.md')
            AddOnlyPathList = @('README.md')
        })

        $message | Should -Match '\.github/agents/'
        $message | Should -Match 'AGENTS\.md'
        $message | Should -Match 'README\.md'
    }
}

Describe 'Confirm-NovaAgenticCopilotScaffoldWarning' {
    It 'skips prompting when OverrideWarningRequested is set' {
        Mock Read-NovaAgenticCopilotScaffoldWarningChoice {throw 'should not be called'}

        {
            Confirm-NovaAgenticCopilotScaffoldWarning -WorkflowContext ([pscustomobject]@{
                OverrideWarningRequested = $true
                ProjectRoot = '/repo'
                ManagedOverwritePathList = @()
                AddOnlyPathList = @()
            })
        } | Should -Not -Throw
    }

    It 'throws a cancellation error when the user declines the apply' {
        Mock Read-NovaAgenticCopilotScaffoldWarningChoice {1}

        {
            Confirm-NovaAgenticCopilotScaffoldWarning -WorkflowContext ([pscustomobject]@{
                OverrideWarningRequested = $false
                ProjectRoot = '/repo'
                ManagedOverwritePathList = @('.github/agents/')
                AddOnlyPathList = @('README.md')
            })
        } | Should -Throw -ErrorId 'Nova.Workflow.AgenticCopilotScaffoldCancelled'
    }
}

Describe 'Invoke-NovaAgenticCopilotScaffoldWorkflow' {
    BeforeEach {
        Mock Confirm-NovaAgenticCopilotScaffoldWarning {}
        Mock Initialize-NovaModuleAgenticCopilotScaffold {}
        Mock Write-Message {}
    }

    It 'returns without applying when ShouldRun is false' {
        Invoke-NovaAgenticCopilotScaffoldWorkflow -WorkflowContext ([pscustomobject]@{
            ProjectRoot = '/repo'
            ProjectInfo = [pscustomobject]@{ProjectName = 'Demo'}
            AnswerSet = @{}
            ScaffoldPolicy = [pscustomobject]@{}
        })

        Assert-MockCalled Initialize-NovaModuleAgenticCopilotScaffold -Times 0
    }

    It 'confirms, applies, and announces when ShouldRun is true' {
        $workflowContext = [pscustomobject]@{
            ProjectRoot = '/repo'
            ProjectInfo = [pscustomobject]@{ProjectName = 'Demo'}
            AnswerSet = @{ProjectName = 'Demo'; ProjectShortName = 'NMT'}
            ScaffoldPolicy = [pscustomobject]@{ManagedOverwritePathList = @(); AddOnlyPathList = @()}
            OverrideWarningRequested = $false
            ManagedOverwritePathList = @('.github/agents/')
            AddOnlyPathList = @('README.md')
        }

        Invoke-NovaAgenticCopilotScaffoldWorkflow -WorkflowContext $workflowContext -ShouldRun

        Assert-MockCalled Confirm-NovaAgenticCopilotScaffoldWarning -Times 1
        Assert-MockCalled Initialize-NovaModuleAgenticCopilotScaffold -Times 1
        Assert-MockCalled Write-Message -Times 1
    }
}
