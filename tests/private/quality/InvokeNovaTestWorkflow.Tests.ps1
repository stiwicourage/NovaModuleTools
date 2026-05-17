BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/InvokeNovaTestWorkflow.ps1')

    . (Join-Path $PSScriptRoot 'InvokeNovaTestWorkflow.TestSupport.ps1')
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

    It 'falls back to CodeCoverage as the target object when the workflow context has no test result path' {
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{
                Pester = [ordered]@{CodeCoverage = [ordered]@{Enabled = $true; CoveragePercentTarget = 90}}
            }
        }

        $assertion = Get-NovaCoverageTargetAssertionScriptBlock -WorkflowContext $workflowContext

        $thrown = $null
        try {
            & $assertion -WorkflowContext $workflowContext -TestResult ([pscustomobject]@{Result = 'Passed'})
        } catch {
            $thrown = $_
        }

        $thrown | Should -Not -BeNullOrEmpty
        $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Workflow.CodeCoveragePercentMissing'
        $thrown.TargetObject | Should -Be 'CodeCoverage'
    }

    It 'treats a blank configured coverage target as not configured' {
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{
                Pester = [ordered]@{CodeCoverage = [ordered]@{Enabled = $true; CoveragePercentTarget = ''}}
            }
        }

        Get-NovaConfiguredCoveragePercentTarget -WorkflowContext $workflowContext | Should -BeNullOrEmpty
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

    It 'handles workflow execution control for <Name>' -ForEach @(
        @{
            Name = 'a requested build'
            BuildRequested = $true
            WorkflowParams = @{}
            ShouldRun = $true
            PesterResult = [pscustomobject]@{Result = 'Passed'}
            ExpectedBuildCalls = 1
            ExpectedPesterCalls = 1
            ExpectedErrorId = $null
        }
        @{
            Name = 'an explicit ShouldRun=false'
            BuildRequested = $false
            WorkflowParams = @{}
            ShouldRun = $false
            PesterResult = [pscustomobject]@{Result = 'Passed'}
            ExpectedBuildCalls = 0
            ExpectedPesterCalls = 0
            ExpectedErrorId = $null
        }
        @{
            Name = 'a WhatIf workflow parameter'
            BuildRequested = $false
            WorkflowParams = @{WhatIf = $true}
            ShouldRun = $true
            PesterResult = [pscustomobject]@{Result = 'Passed'}
            ExpectedBuildCalls = 0
            ExpectedPesterCalls = 0
            ExpectedErrorId = $null
        }
        @{
            Name = 'a failed Pester result'
            BuildRequested = $false
            WorkflowParams = @{}
            ShouldRun = $true
            PesterResult = [pscustomobject]@{Result = 'Failed'}
            ExpectedBuildCalls = 0
            ExpectedPesterCalls = 1
            ExpectedErrorId = 'Nova.Workflow.TestRunFailed'
        }
    ) {
        $workflowContext = New-NovaInvokeNovaTestWorkflowContext -BuildRequested $BuildRequested -WorkflowParams $WorkflowParams
        Mock Invoke-NovaBuild {}
        Mock Test-Path {$true}
        Mock Invoke-NovaPester {$PesterResult}

        $thrown = $null
        try {
            if ($ShouldRun) {
                Invoke-NovaTestWorkflow -WorkflowContext $workflowContext
            }
            else {
                Invoke-NovaTestWorkflow -WorkflowContext $workflowContext -ShouldRun:$false
            }
        } catch {
            $thrown = $_
        }

        if ($ExpectedErrorId) {
            $thrown | Should -Not -BeNullOrEmpty
            $thrown.FullyQualifiedErrorId | Should -Be $ExpectedErrorId
        }
        else {
            $thrown | Should -BeNullOrEmpty
        }

        Should -Invoke Invoke-NovaBuild -Times $ExpectedBuildCalls
        Should -Invoke Invoke-NovaPester -Times $ExpectedPesterCalls
    }

    It 'creates the artifact directory when it does not exist' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{Pester = [ordered]@{}}
            TestResultDirectory = $tempDir
            TestResultPath = (Join-Path $tempDir 'TestResults.xml')
            PesterConfig = [pscustomobject]@{TestResult = [pscustomobject]@{OutputPath = $null}}
            TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
            TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
        }
        Mock Invoke-NovaPester {[pscustomobject]@{Result = 'Passed'}}
        try {
            Invoke-NovaTestWorkflow -WorkflowContext $workflowContext
            Test-Path -LiteralPath $tempDir | Should -BeTrue
        } finally {
            Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

}
