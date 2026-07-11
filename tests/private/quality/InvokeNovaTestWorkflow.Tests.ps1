BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/quality/GetNovaPesterRuntimeMajorVersion.ps1')
    . (Join-Path $projectRoot 'src/private/quality/InvokeNovaPester.ps1')
    . (Join-Path $projectRoot 'src/private/quality/InvokeNovaTestWorkflow.ps1')

    . (Join-Path $PSScriptRoot 'InvokeNovaTestWorkflow.TestSupport.ps1')
}

Describe 'Invoke-NovaTestWorkflow' {
    BeforeEach {
        Mock Write-Message {}
        Mock Write-Warning {}
        Mock Write-Progress {}
        Mock Get-NovaPesterRuntimeMajorVersion {5}
        Mock Invoke-NovaPesterWithSuppressedProgress {[pscustomobject]@{Result = 'Passed'}}
    }

    It 'uses the pre-resolved coverage assertion after the Pester run' {
        $global:coverageAssertionRan = $false
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'; Pester = [ordered]@{}}
            TestResultDirectory = '/tmp/nova-project/artifacts'
            CommandName = 'Invoke-NovaTest'
            TestResultPath = '/tmp/nova-project/artifacts/UnitTestResults.xml'
            PesterConfig = [pscustomobject]@{TestResult = [pscustomobject]@{OutputPath = $null}}
            TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
            TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
            CoverageTargetAssertion = [pscustomobject]@{
                ScriptBlock = {param($WorkflowContext, $TestResult) $global:coverageAssertionRan = $true}
            }
        }

        try {
            Mock Test-Path {$true}

            {Invoke-NovaTestWorkflow -WorkflowContext $workflowContext} | Should -Not -Throw
            $global:coverageAssertionRan | Should -BeTrue
            Should -Invoke Write-Progress -Times 4
            Should -Invoke Write-Progress -Times 1 -ParameterFilter {
                $Status -eq 'Preparing the test result directory' -and $PercentComplete -eq 40
            }
            Should -Invoke Write-Progress -Times 1 -ParameterFilter {
                $Status -eq 'Writing the test result report' -and $PercentComplete -eq 96
            }
            Should -Invoke Write-Progress -Times 1 -ParameterFilter {
                $Status -eq 'Checking the configured code coverage target' -and $PercentComplete -eq 99
            }
            Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
        } finally {
            Remove-Variable -Name coverageAssertionRan -Scope Global -ErrorAction SilentlyContinue
        }
    }

    It 'reports coverage target failures clearly for <Name>' -ForEach @(
        @{
            Name = 'coverage below target'
            PesterResult = [pscustomobject]@{Result = 'Passed'; CodeCoverage = [pscustomobject]@{CoveragePercent = 66.67}}
            ExpectedMessage = 'Code coverage 66.67% did not meet the configured target 90%. Review the failing tests or coverage settings, then rerun Invoke-NovaTest.'
            ExpectedErrorId = 'Nova.Workflow.CodeCoverageTargetNotMet'
            ExpectedCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
        }
        @{
            Name = 'missing measured coverage'
            PesterResult = [pscustomobject]@{Result = 'Passed'}
            ExpectedMessage = 'Code coverage target 90% is configured, but the Pester result did not include a coverage percentage. Review the coverage settings in project.json and the test result file at /tmp/nova-project/artifacts/UnitTestResults.xml.'
            ExpectedErrorId = 'Nova.Workflow.CodeCoveragePercentMissing'
            ExpectedCategory = [System.Management.Automation.ErrorCategory]::InvalidData
        }
    ) {
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{
                ProjectName = 'NovaModuleTools'
                Pester = [ordered]@{CodeCoverage = [ordered]@{Enabled = $true; CoveragePercentTarget = 90}}
            }
            TestResultDirectory = '/tmp/nova-project/artifacts'
            CommandName = 'Invoke-NovaTest'
            TestResultPath = '/tmp/nova-project/artifacts/UnitTestResults.xml'
            PesterConfig = [pscustomobject]@{TestResult = [pscustomobject]@{OutputPath = $null}}
            TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
            TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
        }

        Mock Test-Path {$true}
        Mock Invoke-NovaPesterWithSuppressedProgress {$PesterResult}.GetNewClosure()

        $thrown = $null
        try {Invoke-NovaTestWorkflow -WorkflowContext $workflowContext} catch {$thrown = $_}

        $thrown | Should -Not -BeNullOrEmpty
        $thrown.Exception.Message | Should -Be $ExpectedMessage
        $thrown.FullyQualifiedErrorId | Should -Be $ExpectedErrorId
        $thrown.CategoryInfo.Category | Should -Be $ExpectedCategory
        $thrown.TargetObject | Should -Be '/tmp/nova-project/artifacts/UnitTestResults.xml'
    }

    It 'does not enforce a coverage threshold when project.json does not configure one' {
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'; Pester = [ordered]@{}}
            TestResultDirectory = '/tmp/nova-project/artifacts'
            CommandName = 'Invoke-NovaTest'
            TestResultPath = '/tmp/nova-project/artifacts/UnitTestResults.xml'
            PesterConfig = [pscustomobject]@{TestResult = [pscustomobject]@{OutputPath = $null}}
            TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
            TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
        }

        Mock Test-Path {$true}
        Mock Invoke-NovaPesterWithSuppressedProgress {
            [pscustomobject]@{Result = 'Passed'; CodeCoverage = [pscustomobject]@{CoveragePercent = 10}}
        }

        {Invoke-NovaTestWorkflow -WorkflowContext $workflowContext} | Should -Not -Throw
        $workflowContext.PesterConfig.TestResult.OutputPath | Should -Be '/tmp/nova-project/artifacts/UnitTestResults.xml'
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
            ExpectedMessageCount = 4
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
            ExpectedMessageCount = 0
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
            ExpectedMessageCount = 4
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
            ExpectedMessageCount = 0
        }
    ) {
        $workflowContext = New-NovaInvokeNovaTestWorkflowContext -Option @{
            BuildRequested = $BuildRequested
            WorkflowParams = $WorkflowParams
        }
        Mock Invoke-NovaBuild {}
        Mock Test-Path {$true}
        Mock Invoke-NovaPesterWithSuppressedProgress {$PesterResult}

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
            if ($ExpectedErrorId -eq 'Nova.Workflow.TestRunFailed') {
                $thrown.Exception.Message | Should -Be 'Pester reported one or more failing tests. Review the output above and the test result file at /tmp/nova-project/artifacts/UnitTestResults.xml, then rerun Invoke-NovaTest.'
            }
        }
        else {
            $thrown | Should -BeNullOrEmpty
        }

        Should -Invoke Invoke-NovaBuild -Times $ExpectedBuildCalls
        Should -Invoke Invoke-NovaPesterWithSuppressedProgress -Times $ExpectedPesterCalls
    }

    It 'creates the artifact directory when it does not exist' {
        $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'; Pester = [ordered]@{}}
            TestResultDirectory = $tempDir
            CommandName = 'Invoke-NovaTest'
            TestResultPath = (Join-Path $tempDir 'UnitTestResults.xml')
            PesterConfig = [pscustomobject]@{TestResult = [pscustomobject]@{OutputPath = $null}}
            TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
            TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
        }
        Mock Invoke-NovaPesterWithSuppressedProgress {[pscustomobject]@{Result = 'Passed'}}
        try {
            Invoke-NovaTestWorkflow -WorkflowContext $workflowContext
            Test-Path -LiteralPath $tempDir | Should -BeTrue
        } finally {
            Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'uses the direct Pester wrapper for Pester 6 and later' {
        $workflowContext = New-NovaInvokeNovaTestWorkflowContext
        Mock Test-Path {$true}
        Mock Get-NovaPesterRuntimeMajorVersion {6}
        Mock Invoke-NovaPester {[pscustomobject]@{Result = 'Passed'}}

        {Invoke-NovaTestWorkflow -WorkflowContext $workflowContext} | Should -Not -Throw

        Should -Invoke Invoke-NovaPester -Times 1
        Should -Invoke Invoke-NovaPesterWithSuppressedProgress -Times 0
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Running Pester tests' -and $PercentComplete -eq 70
        }
    }

    It 'writes a test plan summary in WhatIf mode after previewing the nested build step' {
        $workflowContext = New-NovaInvokeNovaTestWorkflowContext -Option @{
            BuildRequested = $true
            WorkflowParams = @{WhatIf = $true}
            PesterSettings = @{
                CodeCoverage = [ordered]@{
                    Enabled = $true
                    CoveragePercentTarget = 99
                }
            }
        }
        Mock Invoke-NovaBuild {}
        Mock Invoke-NovaPesterWithSuppressedProgress {}

        Invoke-NovaTestWorkflow -WorkflowContext $workflowContext

        Should -Invoke Invoke-NovaBuild -Times 1
        Should -Invoke Invoke-NovaPesterWithSuppressedProgress -Times 0
        Should -Invoke Write-Message -Times 5
        Should -Invoke Write-Progress -Times 2
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Previewing the build-before-test workflow' -and $PercentComplete -eq 20
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
        Should -Invoke Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Test plan ready for NovaModuleTools' -and $color -eq 'Green'
        }
        Should -Invoke Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Configured coverage target: 99%'
        }
        Should -Invoke Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Run Invoke-NovaTest without -WhatIf when you are ready to execute the test workflow.'
        }
    }

    It 'warns and skips execution when no build-validation integration tests were discovered' {
        $workflowContext = New-NovaInvokeNovaTestWorkflowContext -Option @{
            BuildRequested = $true
            CommandName = 'Test-NovaBuild'
        }
        $workflowContext | Add-Member -NotePropertyName TestsDiscovered -NotePropertyValue $false
        $workflowContext | Add-Member -NotePropertyName TestDiscoveryMessageLines -NotePropertyValue @(
            "No build-validation integration tests matching '*.Integration.Tests.ps1' were discovered for NovaModuleTools."
            'Test-NovaBuild expects build-validation tests under the tests folder, for example /tmp/nova-project/tests/public/Get-CommandName.Integration.Tests.ps1.'
            'Add at least one *.Integration.Tests.ps1 file, then rerun Test-NovaBuild.'
            'Use Invoke-NovaTest for unit tests and Test-NovaBuild for build-validation integration tests.'
        )
        Mock Invoke-NovaBuild {}
        Mock Invoke-NovaPesterWithSuppressedProgress {}

        { Invoke-NovaTestWorkflow -WorkflowContext $workflowContext } | Should -Not -Throw

        Should -Invoke Invoke-NovaBuild -Times 1
        Should -Invoke Invoke-NovaPesterWithSuppressedProgress -Times 0
        Should -Invoke Write-Warning -Times 1 -ParameterFilter {
            $Message -eq "No build-validation integration tests matching '*.Integration.Tests.ps1' were discovered for NovaModuleTools."
        }
        Should -Invoke Write-Message -Times 3
        Should -Invoke Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Use Invoke-NovaTest for unit tests and Test-NovaBuild for build-validation integration tests.'
        }
    }

}

Describe 'Invoke-NovaPesterWithSuppressedProgress' {
    BeforeEach {
        $script:outputCallCount = 0
        Mock Complete-NovaPesterExecution {}
    }

    It 'writes progress from discovered and completed tests until the Pester execution completes' {
        $execution = [pscustomobject]@{
            PowerShell = [pscustomobject]@{}
            AsyncResult = [pscustomobject]@{}
            CompletedTestCount = 0
            TotalTestCount = $null
            LastProgressStatus = $null
            LastProgressPercentComplete = $null
        }
        $waitResults = [System.Collections.Queue]::new()
        $waitResults.Enqueue($false)
        $waitResults.Enqueue($false)
        $waitResults.Enqueue($true)

        Mock Write-Progress {}
        Mock Get-NovaPesterExecution {$execution}
        Mock Wait-NovaPesterExecution {$waitResults.Dequeue()}
        Mock Receive-NovaPesterExecutionResult {[pscustomobject]@{Result = 'Passed'}}
        Mock Write-NovaPesterExecutionOutput {
            switch ($script:outputCallCount) {
                0 {$Execution.TotalTestCount = 2}
                1 {$Execution.CompletedTestCount = 1}
                2 {$Execution.CompletedTestCount = 2}
            }

            $script:outputCallCount += 1
        }

        $result = Invoke-NovaPesterWithSuppressedProgress -Configuration ([pscustomobject]@{}) -ProgressContext ([pscustomobject]@{
            Activity = 'Running Nova test workflow'
            StartPercentComplete = 70
            EndPercentComplete = 94
            HeartbeatMilliseconds = 2000
        })

        $result.Result | Should -Be 'Passed'
        Should -Invoke Get-NovaPesterExecution -Times 1
        Should -Invoke Wait-NovaPesterExecution -Times 3
        Should -Invoke Write-NovaPesterExecutionOutput -Times 3
        Should -Invoke Receive-NovaPesterExecutionResult -Times 1
        Should -Invoke Complete-NovaPesterExecution -Times 1
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Discovering Pester tests' -and $PercentComplete -eq 70
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Running Pester tests' -and $PercentComplete -eq 70
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Running Pester tests' -and $PercentComplete -eq 82
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Running Pester tests' -and $PercentComplete -eq 94
        }
    }

    It 'stops the async execution when receiving the Pester result throws' {
        $execution = [pscustomobject]@{
            PowerShell = [pscustomobject]@{}
            AsyncResult = [pscustomobject]@{}
            CompletedTestCount = 0
            TotalTestCount = $null
            LastProgressStatus = $null
            LastProgressPercentComplete = $null
        }

        Mock Write-Progress {}
        Mock Get-NovaPesterExecution {$execution}
        Mock Wait-NovaPesterExecution {$true}
        Mock Receive-NovaPesterExecutionResult {throw 'boom'}
        Mock Write-NovaPesterExecutionOutput {}

        { Invoke-NovaPesterWithSuppressedProgress -Configuration ([pscustomobject]@{}) -ProgressContext ([pscustomobject]@{
                Activity = 'Running Nova test workflow'
                StartPercentComplete = 70
                EndPercentComplete = 94
            }) } | Should -Throw
        Should -Invoke Write-NovaPesterExecutionOutput -Times 1
        Should -Invoke Complete-NovaPesterExecution -Times 1
    }
}

Describe 'Write-NovaPesterExecutionOutput' {
    BeforeEach {
        Mock Write-Host {}
        Mock Write-Information {}
    }

    It 'writes pending host information records, tracks discovery, and advances the cursor' {
        $execution = [pscustomobject]@{
            PowerShell = [pscustomobject]@{
                Streams = [pscustomobject]@{
                    Information = @(
                        [pscustomobject]@{
                            Tags = @('PSHOST')
                            MessageData = [pscustomobject]@{
                                Message = 'Discovery found 2 tests in 50ms.'
                                NoNewLine = $false
                                ForegroundColor = $null
                                BackgroundColor = $null
                            }
                        }
                        [pscustomobject]@{
                            Tags = @('PSHOST')
                            MessageData = [pscustomobject]@{
                                Message = '  [+] first'
                                NoNewLine = $true
                                ForegroundColor = 'DarkGreen'
                                BackgroundColor = $null
                            }
                        }
                        [pscustomobject]@{
                            Tags = @('PSHOST')
                            MessageData = [pscustomobject]@{
                                Message = ' second'
                                NoNewLine = $false
                                ForegroundColor = 'DarkGray'
                                BackgroundColor = $null
                            }
                        }
                    )
                }
            }
            CompletedTestCount = 0
            NextInformationRecordIndex = 0
            TotalTestCount = $null
        }

        Write-NovaPesterExecutionOutput -Execution $execution
        Write-NovaPesterExecutionOutput -Execution $execution

        $execution.NextInformationRecordIndex | Should -Be 3
        $execution.CompletedTestCount | Should -Be 1
        $execution.TotalTestCount | Should -Be 2
        Should -Invoke Write-Host -Times 1 -ParameterFilter {
            $Object -eq '  [+] first' -and $NoNewline -and $ForegroundColor -eq 'DarkGreen'
        }
        Should -Invoke Write-Host -Times 1 -ParameterFilter {
            $Object -eq ' second' -and -not $NoNewline -and $ForegroundColor -eq 'DarkGray'
        }
        Should -Invoke Write-Information -Times 0
    }

    It 'forwards non-host information records through Write-Information' {
        $execution = [pscustomobject]@{
            PowerShell = [pscustomobject]@{
                Streams = [pscustomobject]@{
                    Information = @(
                        [pscustomobject]@{
                            Tags = @('Pester')
                            MessageData = 'discovery'
                        }
                    )
                }
            }
            NextInformationRecordIndex = 0
        }

        Write-NovaPesterExecutionOutput -Execution $execution

        $execution.NextInformationRecordIndex | Should -Be 1
        Should -Invoke Write-Host -Times 0
        Should -Invoke Write-Information -Times 1 -ParameterFilter {
            $MessageData -eq 'discovery' -and $Tags.Count -eq 1 -and $Tags[0] -eq 'Pester' -and $InformationAction -eq 'Continue'
        }
    }

    It 'initializes the record index to zero when the property value is null' {
        $execution = [pscustomobject]@{
            PowerShell = [pscustomobject]@{
                Streams = [pscustomobject]@{Information = @()}
            }
            CompletedTestCount = 0
            TotalTestCount = $null
            NextInformationRecordIndex = $null
        }

        Write-NovaPesterExecutionOutput -Execution $execution

        $execution.NextInformationRecordIndex | Should -Be 0
    }
}

Describe 'Get-NovaTestWorkflowCoverageMessage' {
    It 'includes the measured and configured coverage values when both are available' {
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{
                Pester = [ordered]@{
                    CodeCoverage = [ordered]@{
                        Enabled = $true
                        CoveragePercentTarget = 90
                    }
                }
            }
        }

        $testResult = [pscustomobject]@{
            CodeCoverage = [pscustomobject]@{
                CoveragePercent = 66.67
            }
        }

        Get-NovaTestWorkflowCoverageMessage -WorkflowContext $workflowContext -TestResult $testResult | Should -Be 'Measured code coverage: 66.67% (target: 90%)'
    }
}

Describe 'Get-NovaTestWorkflowPesterPercentComplete' {
    It 'uses discovered and completed test counts to calculate progress' {
        Get-NovaTestWorkflowPesterPercentComplete -StartPercentComplete 70 -EndPercentComplete 94 -CompletedTestCount 1 -TotalTestCount 2 | Should -Be 82
    }

    It 'stays at the start percent until discovery finds the total test count' {
        Get-NovaTestWorkflowPesterPercentComplete -StartPercentComplete 70 -EndPercentComplete 94 -CompletedTestCount 0 -TotalTestCount $null | Should -Be 70
    }

    It 'caps completed test progress at the configured end percent' {
        Get-NovaTestWorkflowPesterPercentComplete -StartPercentComplete 70 -EndPercentComplete 94 -CompletedTestCount 5 -TotalTestCount 4 | Should -Be 94
    }

    It 'returns the end percent immediately when the total test count is zero' {
        Get-NovaTestWorkflowPesterPercentComplete -StartPercentComplete 70 -EndPercentComplete 94 -CompletedTestCount 0 -TotalTestCount 0 | Should -Be 94
    }

    It 'returns the start percent when the computed value falls below the range minimum' {
        Get-NovaTestWorkflowPesterPercentComplete -StartPercentComplete 94 -EndPercentComplete 70 -CompletedTestCount 5 -TotalTestCount 4 | Should -Be 94
    }
}

Describe 'Get-NovaPesterExecutionInformationRecordBuffer' {
    It 'returns an empty array when the execution has no PowerShell' {
        $execution = [pscustomobject]@{PowerShell = $null}
        $result = @(Get-NovaPesterExecutionInformationRecordBuffer -Execution $execution)
        $result.Count | Should -Be 0
    }
}

Describe 'Get-NovaPesterExecution' {
    It 'returns an execution object with the expected initial properties' {
        $execution = $null
        try {
            $execution = Get-NovaPesterExecution -Configuration ([pscustomobject]@{})
            $execution.PowerShell | Should -Not -BeNullOrEmpty
            $execution.AsyncResult | Should -Not -BeNullOrEmpty
            $execution.CompletedTestCount | Should -Be 0
            $execution.NextInformationRecordIndex | Should -Be 0
            $execution.TotalTestCount | Should -BeNullOrEmpty
            $execution.LastProgressStatus | Should -BeNullOrEmpty
            $execution.LastProgressPercentComplete | Should -BeNullOrEmpty
        } finally {
            if ($null -ne $execution -and $null -ne $execution.PowerShell) {
                $execution.PowerShell.Dispose()
            }
        }
    }
}

Describe 'Wait-NovaPesterExecution' {
    It 'returns true when the async operation completes within the timeout' {
        $ps = [powershell]::Create()
        $null = $ps.AddScript('return 0')
        $asyncResult = $ps.BeginInvoke()
        $execution = [pscustomobject]@{PowerShell = $ps; AsyncResult = $asyncResult}
        try {
            $result = Wait-NovaPesterExecution -Execution $execution -TimeoutMilliseconds 30000
            $result | Should -BeTrue
        } finally {
            $ps.Dispose()
        }
    }
}

Describe 'Receive-NovaPesterExecutionResult' {
    It 'returns the last output object from the completed execution' {
        $ps = [powershell]::Create()
        $null = $ps.AddScript('[pscustomobject]@{Result = "Passed"}')
        $asyncResult = $ps.BeginInvoke()
        $execution = [pscustomobject]@{PowerShell = $ps; AsyncResult = $asyncResult}
        try {
            $null = $asyncResult.AsyncWaitHandle.WaitOne(30000)
            $result = Receive-NovaPesterExecutionResult -Execution $execution
            $result.Result | Should -Be 'Passed'
        } finally {
            $ps.Dispose()
        }
    }
}

Describe 'Complete-NovaPesterExecution' {
    It 'returns immediately when the execution is null' {
        { Complete-NovaPesterExecution -Execution $null } | Should -Not -Throw
    }

    It 'returns immediately when the PowerShell property is null' {
        $execution = [pscustomobject]@{PowerShell = $null}
        { Complete-NovaPesterExecution -Execution $execution } | Should -Not -Throw
    }

    It 'disposes the PowerShell instance' {
        $ps = [powershell]::Create()
        $null = $ps.AddScript('return 0')
        $execution = [pscustomobject]@{PowerShell = $ps}
        { Complete-NovaPesterExecution -Execution $execution } | Should -Not -Throw
    }
}
