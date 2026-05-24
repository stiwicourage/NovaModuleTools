BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/scaffold/GetNovaAgenticCopilotScaffoldWorkflowContext.ps1')

    function Stop-NovaOperation {
        param([string]$Message, [string]$ErrorId, [System.Management.Automation.ErrorCategory]$Category, $TargetObject)
        $exception = [System.Exception]::new($Message)
        $record = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
        throw $record
    }
}

Describe 'Assert-NovaAgenticCopilotShortName' {
    It 'throws when the short name is blank' {
        {Assert-NovaAgenticCopilotShortName -ShortName ' '} | Should -Throw -ErrorId 'Nova.Validation.AgenticCopilotProjectShortNameMissing'
    }

    It 'throws when the short name is invalid' {
        {Assert-NovaAgenticCopilotShortName -ShortName 'bad name'} | Should -Throw -ErrorId 'Nova.Validation.ScaffoldProjectShortNameInvalid'
    }

    It 'accepts an alphanumeric short name that starts with a letter' {
        {Assert-NovaAgenticCopilotShortName -ShortName 'NMT1'} | Should -Not -Throw
    }
}

Describe 'Test-NovaAgenticCopilotProjectUsesPester' {
    It 'returns true when project info contains a Pester property' {
        Test-NovaAgenticCopilotProjectUsesPester -ProjectInfo ([pscustomobject]@{Pester = @{}}) | Should -BeTrue
    }

    It 'returns false when project info does not contain a Pester property' {
        Test-NovaAgenticCopilotProjectUsesPester -ProjectInfo ([pscustomobject]@{ProjectName = 'Demo'}) | Should -BeFalse
    }
}

Describe 'Get-NovaAgenticCopilotScaffoldWorkflowContext' {
    It 'builds the workflow context from project metadata and short name' {
        Mock Get-NovaProjectInfo {
            [pscustomobject]@{
                ProjectRoot = '/repo'
                ProjectName = 'Demo.Module'
                Description = 'Demo module'
                Pester = @{Enabled = $true}
            }
        }

        $context = Get-NovaAgenticCopilotScaffoldWorkflowContext -Path '/repo' -ShortName 'NMT' -OverrideWarningRequested

        $context.ProjectRoot | Should -Be '/repo'
        $context.AnswerSet.ProjectName | Should -Be 'Demo.Module'
        $context.AnswerSet.Description | Should -Be 'Demo module'
        $context.AnswerSet.ProjectShortName | Should -Be 'NMT'
        $context.AnswerSet.EnablePester | Should -Be 'Yes'
        $context.OverrideWarningRequested | Should -BeTrue
        $context.ManagedOverwritePathList | Should -Contain '.github/agents/'
        $context.AddOnlyPathList | Should -Contain 'README.md'
        $context.Action | Should -Be 'Apply Nova Agentic Copilot scaffold'
    }

    It 'marks projects without Pester as EnablePester = No' {
        Mock Get-NovaProjectInfo {
            [pscustomobject]@{
                ProjectRoot = '/repo'
                ProjectName = 'Demo.Module'
                Description = 'Demo module'
            }
        }

        (Get-NovaAgenticCopilotScaffoldWorkflowContext -Path '/repo' -ShortName 'NMT').AnswerSet.EnablePester | Should -Be 'No'
    }
}
