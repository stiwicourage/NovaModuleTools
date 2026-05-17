BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/InvokeNovaTestWorkflow.ps1')

    function Stop-NovaOperation {
        param($Message, $ErrorId, $Category, $TargetObject)
        $exception = switch ($Category) {
            ([System.Management.Automation.ErrorCategory]::InvalidData) {[System.IO.InvalidDataException]::new($Message)}
            default {[System.InvalidOperationException]::new($Message)}
        }
        $errorRecord = [System.Management.Automation.ErrorRecord]::new($exception, $ErrorId, $Category, $TargetObject)
        throw $errorRecord
    }
    function Invoke-NovaBuild {}
    function Invoke-NovaPester {param($Configuration)}
    function Get-NovaBuildCommandParameterMap {param($WorkflowParams, [switch]$OverrideWarningRequested) return @{}}
}

Describe 'Invoke-NovaTestWorkflow' {
    It 'uses the pre-resolved coverage assertion after the Pester run' {
        $global:coverageAssertionRan = $false
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{Pester = [ordered]@{}}
            TestResultDirectory = '/tmp/nova-project/artifacts'
            TestResultPath = '/tmp/nova-project/artifacts/TestResults.xml'
            PesterConfig = [pscustomobject]@{TestResult = [pscustomobject]@{OutputPath = $null}}
            TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
            TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
            CoverageTargetAssertion = [pscustomobject]@{
                ScriptBlock = {param($WorkflowContext, $TestResult) $global:coverageAssertionRan = $true}
            }
        }

        try {
            Mock Test-Path {$true}
            Mock Invoke-NovaPester {[pscustomobject]@{Result = 'Passed'}}

            {Invoke-NovaTestWorkflow -WorkflowContext $workflowContext} | Should -Not -Throw
            $global:coverageAssertionRan | Should -BeTrue
        } finally {
            Remove-Variable -Name coverageAssertionRan -Scope Global -ErrorAction SilentlyContinue
        }
    }

    It 'reports coverage target failures clearly for <Name>' -ForEach @(
        @{
            Name = 'coverage below target'
            PesterResult = [pscustomobject]@{Result = 'Passed'; CodeCoverage = [pscustomobject]@{CoveragePercent = 66.67}}
            ExpectedMessage = 'Code coverage 66.67% did not meet the configured target 90%.'
            ExpectedErrorId = 'Nova.Workflow.CodeCoverageTargetNotMet'
            ExpectedCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
        }
        @{
            Name = 'missing measured coverage'
            PesterResult = [pscustomobject]@{Result = 'Passed'}
            ExpectedMessage = 'Code coverage target 90% is configured, but the Pester result did not include a coverage percentage.'
            ExpectedErrorId = 'Nova.Workflow.CodeCoveragePercentMissing'
            ExpectedCategory = [System.Management.Automation.ErrorCategory]::InvalidData
        }
    ) {
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{
                Pester = [ordered]@{CodeCoverage = [ordered]@{Enabled = $true; CoveragePercentTarget = 90}}
            }
            TestResultDirectory = '/tmp/nova-project/artifacts'
            TestResultPath = '/tmp/nova-project/artifacts/TestResults.xml'
            PesterConfig = [pscustomobject]@{TestResult = [pscustomobject]@{OutputPath = $null}}
            TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
            TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
        }

        Mock Test-Path {$true}
        Mock Invoke-NovaPester {$PesterResult}.GetNewClosure()

        $thrown = $null
        try {Invoke-NovaTestWorkflow -WorkflowContext $workflowContext} catch {$thrown = $_}

        $thrown | Should -Not -BeNullOrEmpty
        $thrown.Exception.Message | Should -Be $ExpectedMessage
        $thrown.FullyQualifiedErrorId | Should -Be $ExpectedErrorId
        $thrown.CategoryInfo.Category | Should -Be $ExpectedCategory
        $thrown.TargetObject | Should -Be '/tmp/nova-project/artifacts/TestResults.xml'
    }

    It 'does not enforce a coverage threshold when project.json does not configure one' {
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{Pester = [ordered]@{}}
            TestResultDirectory = '/tmp/nova-project/artifacts'
            TestResultPath = '/tmp/nova-project/artifacts/TestResults.xml'
            PesterConfig = [pscustomobject]@{TestResult = [pscustomobject]@{OutputPath = $null}}
            TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
            TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
        }

        Mock Test-Path {$true}
        Mock Invoke-NovaPester {
            [pscustomobject]@{Result = 'Passed'; CodeCoverage = [pscustomobject]@{CoveragePercent = 10}}
        }

        {Invoke-NovaTestWorkflow -WorkflowContext $workflowContext} | Should -Not -Throw
        $workflowContext.PesterConfig.TestResult.OutputPath | Should -Be '/tmp/nova-project/artifacts/TestResults.xml'
    }

    It 'suppresses global progress output around the Pester run and restores the previous preference' {
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{Pester = [ordered]@{}}
            TestResultDirectory = '/tmp/nova-project/artifacts'
            TestResultPath = '/tmp/nova-project/artifacts/TestResults.xml'
            PesterConfig = [pscustomobject]@{TestResult = [pscustomobject]@{OutputPath = $null}}
            TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
            TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
        }

        $previous = $global:ProgressPreference
        $global:ProgressPreference = 'Continue'
        $global:observedProgressPreferenceDuringPester = $null
        try {
            Mock Test-Path {$true}
            Mock Invoke-NovaPester {
                $global:observedProgressPreferenceDuringPester = $global:ProgressPreference
                [pscustomobject]@{Result = 'Passed'}
            }

            Invoke-NovaTestWorkflow -WorkflowContext $workflowContext

            $global:observedProgressPreferenceDuringPester | Should -Be 'SilentlyContinue'
            $global:ProgressPreference | Should -Be 'Continue'
        } finally {
            $global:ProgressPreference = $previous
            Remove-Variable -Name observedProgressPreferenceDuringPester -Scope Global -ErrorAction SilentlyContinue
        }
    }

    It 'restores the previous progress preference even when Pester throws' {
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{Pester = [ordered]@{}}
            TestResultDirectory = '/tmp/nova-project/artifacts'
            TestResultPath = '/tmp/nova-project/artifacts/TestResults.xml'
            PesterConfig = [pscustomobject]@{TestResult = [pscustomobject]@{OutputPath = $null}}
            TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
            TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
        }

        $previous = $global:ProgressPreference
        $global:ProgressPreference = 'Continue'
        try {
            Mock Test-Path {$true}
            Mock Invoke-NovaPester {throw 'boom'}

            {Invoke-NovaTestWorkflow -WorkflowContext $workflowContext} | Should -Throw

            $global:ProgressPreference | Should -Be 'Continue'
        } finally {
            $global:ProgressPreference = $previous
        }
    }
}
