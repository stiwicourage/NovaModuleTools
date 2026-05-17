Describe 'Invoke-NovaTestWorkflow' {
    BeforeAll {
        $repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
        $moduleName = (Get-Content -LiteralPath (Join-Path $repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
        $distModuleDir = Join-Path $repoRoot "dist/$moduleName"

        if (-not (Test-Path -LiteralPath $distModuleDir)) {
            throw "Expected built $moduleName module at: $distModuleDir. Run Invoke-NovaBuild in the repo root first."
        }

        Remove-Module $moduleName -ErrorAction SilentlyContinue
        Import-Module $distModuleDir -Force
    }

    It 'uses the pre-resolved coverage assertion after the Pester run' {
        $global:coverageAssertionRan = $false
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{
                Pester = [ordered]@{}
            }
            TestResultDirectory = '/tmp/nova-project/artifacts'
            TestResultPath = '/tmp/nova-project/artifacts/TestResults.xml'
            PesterConfig = [pscustomobject]@{
                TestResult = [pscustomobject]@{
                    OutputPath = $null
                }
            }
            TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
            TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
            CoverageTargetAssertion = [pscustomobject]@{
                ScriptBlock = {
                    param($WorkflowContext, $TestResult)

                    $global:coverageAssertionRan = $true
                }
            }
        }

        try {
            InModuleScope $moduleName -Parameters @{WorkflowContext = $workflowContext} {
                param($WorkflowContext)

                Mock Test-Path {$true}
                Mock Invoke-NovaPester {
                    [pscustomobject]@{
                        Result = 'Passed'
                    }
                }

                {Invoke-NovaTestWorkflow -WorkflowContext $WorkflowContext} | Should -Not -Throw
            }

            $global:coverageAssertionRan | Should -BeTrue
        } finally {
            Remove-Variable -Name coverageAssertionRan -Scope Global -ErrorAction SilentlyContinue
        }
    }

    It 'reports coverage target failures clearly for <Name>' -ForEach @(
        @{
            Name = 'coverage below target'
            PesterResult = [pscustomobject]@{
                Result = 'Passed'
                CodeCoverage = [pscustomobject]@{
                    CoveragePercent = 66.67
                }
            }
            ExpectedMessage = 'Code coverage 66.67% did not meet the configured target 90%.'
            ExpectedErrorId = 'Nova.Workflow.CodeCoverageTargetNotMet'
            ExpectedCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
        }
        @{
            Name = 'missing measured coverage'
            PesterResult = [pscustomobject]@{
                Result = 'Passed'
            }
            ExpectedMessage = 'Code coverage target 90% is configured, but the Pester result did not include a coverage percentage.'
            ExpectedErrorId = 'Nova.Workflow.CodeCoveragePercentMissing'
            ExpectedCategory = [System.Management.Automation.ErrorCategory]::InvalidData
        }
    ) {
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{
                Pester = [ordered]@{
                    CodeCoverage = [ordered]@{
                        Enabled = $true
                        CoveragePercentTarget = 90
                    }
                }
            }
            TestResultDirectory = '/tmp/nova-project/artifacts'
            TestResultPath = '/tmp/nova-project/artifacts/TestResults.xml'
            PesterConfig = [pscustomobject]@{
                TestResult = [pscustomobject]@{
                    OutputPath = $null
                }
            }
            TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
            TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
        }

        InModuleScope $moduleName -Parameters @{
            WorkflowContext = $workflowContext
            PesterResult = $PesterResult
            ExpectedMessage = $ExpectedMessage
            ExpectedErrorId = $ExpectedErrorId
            ExpectedCategory = $ExpectedCategory
        } {
            param($WorkflowContext, $PesterResult, $ExpectedMessage, $ExpectedErrorId, $ExpectedCategory)

            Mock Test-Path {$true}
            Mock Invoke-NovaPester {$PesterResult}

            $thrown = $null
            try {
                Invoke-NovaTestWorkflow -WorkflowContext $WorkflowContext
            } catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be $ExpectedMessage
            $thrown.FullyQualifiedErrorId | Should -Be $ExpectedErrorId
            $thrown.CategoryInfo.Category | Should -Be $ExpectedCategory
            $thrown.TargetObject | Should -Be '/tmp/nova-project/artifacts/TestResults.xml'
        }
    }

    It 'does not enforce a coverage threshold when project.json does not configure one' {
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{
                Pester = [ordered]@{}
            }
            TestResultDirectory = '/tmp/nova-project/artifacts'
            TestResultPath = '/tmp/nova-project/artifacts/TestResults.xml'
            PesterConfig = [pscustomobject]@{
                TestResult = [pscustomobject]@{
                    OutputPath = $null
                }
            }
            TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
            TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
        }

        InModuleScope $moduleName -Parameters @{WorkflowContext = $workflowContext} {
            param($WorkflowContext)

            Mock Test-Path {$true}
            Mock Invoke-NovaPester {
                [pscustomobject]@{
                    Result = 'Passed'
                    CodeCoverage = [pscustomobject]@{
                        CoveragePercent = 10
                    }
                }
            }

            {Invoke-NovaTestWorkflow -WorkflowContext $WorkflowContext} | Should -Not -Throw
            $WorkflowContext.PesterConfig.TestResult.OutputPath | Should -Be '/tmp/nova-project/artifacts/TestResults.xml'
        }
    }

    It 'suppresses global progress output around the Pester run and restores the previous preference' {
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{
                Pester = [ordered]@{}
            }
            TestResultDirectory = '/tmp/nova-project/artifacts'
            TestResultPath = '/tmp/nova-project/artifacts/TestResults.xml'
            PesterConfig = [pscustomobject]@{
                TestResult = [pscustomobject]@{
                    OutputPath = $null
                }
            }
            TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
            TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
        }

        $previous = $global:ProgressPreference
        $global:ProgressPreference = 'Continue'
        $global:observedProgressPreferenceDuringPester = $null
        try {
            InModuleScope $moduleName -Parameters @{WorkflowContext = $workflowContext} {
                param($WorkflowContext)

                Mock Test-Path {$true}
                Mock Invoke-NovaPester {
                    $global:observedProgressPreferenceDuringPester = $global:ProgressPreference
                    [pscustomobject]@{Result = 'Passed'}
                }

                Invoke-NovaTestWorkflow -WorkflowContext $WorkflowContext
            }

            $global:observedProgressPreferenceDuringPester | Should -Be 'SilentlyContinue'
            $global:ProgressPreference | Should -Be 'Continue'
        } finally {
            $global:ProgressPreference = $previous
            Remove-Variable -Name observedProgressPreferenceDuringPester -Scope Global -ErrorAction SilentlyContinue
        }
    }

    It 'restores the previous progress preference even when Pester throws' {
        $workflowContext = [pscustomobject]@{
            ProjectInfo = [pscustomobject]@{
                Pester = [ordered]@{}
            }
            TestResultDirectory = '/tmp/nova-project/artifacts'
            TestResultPath = '/tmp/nova-project/artifacts/TestResults.xml'
            PesterConfig = [pscustomobject]@{
                TestResult = [pscustomobject]@{
                    OutputPath = $null
                }
            }
            TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
            TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
        }

        $previous = $global:ProgressPreference
        $global:ProgressPreference = 'Continue'
        try {
            InModuleScope $moduleName -Parameters @{WorkflowContext = $workflowContext} {
                param($WorkflowContext)

                Mock Test-Path {$true}
                Mock Invoke-NovaPester {throw 'boom'}

                {Invoke-NovaTestWorkflow -WorkflowContext $WorkflowContext} | Should -Throw
            }

            $global:ProgressPreference | Should -Be 'Continue'
        } finally {
            $global:ProgressPreference = $previous
        }
    }
}
