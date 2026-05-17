BeforeAll {
    $script:repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
    $script:getTestInvokeNovaPesterConfig = {
        return [pscustomobject]@{
            TestResult = [pscustomobject]@{
                OutputPath = $null
            }
        }
    }
    $script:getTestInvokeNovaTestWorkflowContext = {
        param(
            [Parameter(Mandatory)][object]$PesterConfig,
            [Parameter(Mandatory)][object]$ProjectInfo,
            [scriptblock]$CoverageTargetAssertion
        )

        $workflowContext = [pscustomobject]@{
            ProjectInfo = $ProjectInfo
            TestResultDirectory = '/tmp/nova-project/artifacts'
            TestResultPath = '/tmp/nova-project/artifacts/TestResults.xml'
            PesterConfig = $PesterConfig
            TestResultArtifactWriter = [pscustomobject]@{ScriptBlock = {}}
            TestResultReportWriter = [pscustomobject]@{ScriptBlock = {}}
        }

        if ($null -ne $CoverageTargetAssertion) {
            $workflowContext | Add-Member -MemberType NoteProperty -Name CoverageTargetAssertion -Value ([pscustomobject]@{ScriptBlock = $CoverageTargetAssertion})
        }

        return $workflowContext
    }
}

Describe 'Invoke-NovaTestWorkflow' {
    It 'uses the pre-resolved coverage assertion after the Pester run' {
        $global:coverageAssertionRan = $false
        $workflowContext = & $script:getTestInvokeNovaTestWorkflowContext -PesterConfig (& $script:getTestInvokeNovaPesterConfig) -ProjectInfo ([pscustomobject]@{
            Pester = [ordered]@{}
        }) -CoverageTargetAssertion {
            param($WorkflowContext, $TestResult)

            $global:coverageAssertionRan = $true
        }

        try {
            InModuleScope $script:moduleName -Parameters @{WorkflowContext = $workflowContext} {
                param($WorkflowContext)

                Mock Test-Path {$true}
                Mock Invoke-NovaPester {
                    [pscustomobject]@{
                        Result = 'Passed'
                    }
                }

                {Invoke-NovaTestWorkflow -WorkflowContext $workflowContext} | Should -Not -Throw
            }

            $global:coverageAssertionRan | Should -BeTrue
        } finally {
            Remove-Variable -Name coverageAssertionRan -Scope Global -ErrorAction SilentlyContinue
        }
    }

    It 'throws when the configured coverage target is not met' {
        $workflowContext = & $script:getTestInvokeNovaTestWorkflowContext -PesterConfig (& $script:getTestInvokeNovaPesterConfig) -ProjectInfo ([pscustomobject]@{
            Pester = [ordered]@{
                CodeCoverage = [ordered]@{
                    Enabled = $true
                    CoveragePercentTarget = 90
                }
            }
        })

        InModuleScope $script:moduleName -Parameters @{WorkflowContext = $workflowContext} {
            param($WorkflowContext)

            Mock Test-Path {$true}
            Mock Invoke-NovaPester {
                [pscustomobject]@{
                    Result = 'Passed'
                    CodeCoverage = [pscustomobject]@{
                        CoveragePercent = 66.67
                    }
                }
            }

            $thrown = $null
            try {
                Invoke-NovaTestWorkflow -WorkflowContext $workflowContext
            } catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be 'Code coverage 66.67% did not meet the configured target 90%.'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Workflow.CodeCoverageTargetNotMet'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidOperation)
            $thrown.TargetObject | Should -Be '/tmp/nova-project/artifacts/TestResults.xml'
        }
    }

    It 'throws clearly when a configured coverage target has no measured coverage percent' {
        $workflowContext = & $script:getTestInvokeNovaTestWorkflowContext -PesterConfig (& $script:getTestInvokeNovaPesterConfig) -ProjectInfo ([pscustomobject]@{
            Pester = [ordered]@{
                CodeCoverage = [ordered]@{
                    Enabled = $true
                    CoveragePercentTarget = 90
                }
            }
        })

        InModuleScope $script:moduleName -Parameters @{WorkflowContext = $workflowContext} {
            param($WorkflowContext)

            Mock Test-Path {$true}
            Mock Invoke-NovaPester {
                [pscustomobject]@{
                    Result = 'Passed'
                }
            }

            $thrown = $null
            try {
                Invoke-NovaTestWorkflow -WorkflowContext $workflowContext
            } catch {
                $thrown = $_
            }

            $thrown | Should -Not -BeNullOrEmpty
            $thrown.Exception.Message | Should -Be 'Code coverage target 90% is configured, but the Pester result did not include a coverage percentage.'
            $thrown.FullyQualifiedErrorId | Should -Be 'Nova.Workflow.CodeCoveragePercentMissing'
            $thrown.CategoryInfo.Category | Should -Be ([System.Management.Automation.ErrorCategory]::InvalidData)
            $thrown.TargetObject | Should -Be '/tmp/nova-project/artifacts/TestResults.xml'
        }
    }

    It 'does not enforce a coverage threshold when project.json does not configure one' {
        $workflowContext = & $script:getTestInvokeNovaTestWorkflowContext -PesterConfig (& $script:getTestInvokeNovaPesterConfig) -ProjectInfo ([pscustomobject]@{
            Pester = [ordered]@{}
        })

        InModuleScope $script:moduleName -Parameters @{WorkflowContext = $workflowContext} {
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

            {Invoke-NovaTestWorkflow -WorkflowContext $workflowContext} | Should -Not -Throw
            $workflowContext.PesterConfig.TestResult.OutputPath | Should -Be '/tmp/nova-project/artifacts/TestResults.xml'
        }
    }

    It 'suppresses global progress output around the Pester run and restores the previous preference' {
        $workflowContext = & $script:getTestInvokeNovaTestWorkflowContext -PesterConfig (& $script:getTestInvokeNovaPesterConfig) -ProjectInfo ([pscustomobject]@{
            Pester = [ordered]@{}
        })

        $previous = $global:ProgressPreference
        $global:ProgressPreference = 'Continue'
        $global:observedProgressPreferenceDuringPester = $null
        try {
            InModuleScope $script:moduleName -Parameters @{WorkflowContext = $workflowContext} {
                param($WorkflowContext)

                Mock Test-Path {$true}
                Mock Invoke-NovaPester {
                    $global:observedProgressPreferenceDuringPester = $global:ProgressPreference
                    [pscustomobject]@{Result = 'Passed'}
                }

                Invoke-NovaTestWorkflow -WorkflowContext $workflowContext
            }

            $global:observedProgressPreferenceDuringPester | Should -Be 'SilentlyContinue'
            $global:ProgressPreference | Should -Be 'Continue'
        } finally {
            $global:ProgressPreference = $previous
            Remove-Variable -Name observedProgressPreferenceDuringPester -Scope Global -ErrorAction SilentlyContinue
        }
    }

    It 'restores the previous progress preference even when Pester throws' {
        $workflowContext = & $script:getTestInvokeNovaTestWorkflowContext -PesterConfig (& $script:getTestInvokeNovaPesterConfig) -ProjectInfo ([pscustomobject]@{
            Pester = [ordered]@{}
        })

        $previous = $global:ProgressPreference
        $global:ProgressPreference = 'Continue'
        try {
            InModuleScope $script:moduleName -Parameters @{WorkflowContext = $workflowContext} {
                param($WorkflowContext)

                Mock Test-Path {$true}
                Mock Invoke-NovaPester {throw 'boom'}

                {Invoke-NovaTestWorkflow -WorkflowContext $workflowContext} | Should -Throw
            }

            $global:ProgressPreference | Should -Be 'Continue'
        } finally {
            $global:ProgressPreference = $previous
        }
    }
}
