BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/InvokeNovaBuildWorkflow.ps1')

    . (Join-Path $PSScriptRoot 'InvokeNovaBuildWorkflow.TestSupport.ps1')
}

Describe 'Invoke-NovaBuildWorkflow' {
    It 'reports progress, runs the build steps in order, and prints the next suggested validation step' {
        $global:steps = @()
        try {
            $workflowContext = [pscustomobject]@{
                ProjectInfo = [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                    FailOnDuplicateFunctionNames = $true
                }
                ContinuousIntegrationRequested = $false
            }

            Mock Assert-NovaPublicFunctionFileLayout {$global:steps += 'public-layout'}
            Mock Reset-ProjectDist {$global:steps += 'reset'}
            Mock Build-Module {$global:steps += 'module'}
            Mock Assert-BuiltModuleHasNoDuplicateFunctionName {$global:steps += 'duplicates'}
            Mock Build-Manifest {$global:steps += 'manifest'}
            Mock Build-Help {$global:steps += 'help'}
            Mock Copy-ProjectResource {$global:steps += 'resources'}
            Mock Invoke-NovaModuleUpdateNotificationSafely {$global:steps += 'notification'}
            Mock Import-NovaBuiltModuleForCi {$global:steps += 'ci'}
            Mock Write-Message {}
            Mock Write-Progress {}

            Invoke-NovaBuildWorkflow -WorkflowContext $workflowContext

            $global:steps -join ',' | Should -Be 'public-layout,reset,module,duplicates,manifest,help,resources,notification'
            Should -Invoke Invoke-NovaModuleUpdateNotificationSafely -Times 1
            Should -Invoke Import-NovaBuiltModuleForCi -Times 0
            Should -Invoke Write-Progress -Times 9
            Should -Invoke Write-Progress -Times 1 -ParameterFilter {
                $Status -eq 'Validating public command layout' -and $PercentComplete -eq 10
            }
            Should -Invoke Write-Progress -Times 1 -ParameterFilter {
                $Status -eq 'Checking update notifications' -and $PercentComplete -eq 94
            }
            Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
            Should -Invoke Write-Message -Times 5
            Should -Invoke Write-Message -Times 1 -ParameterFilter {
                $Text -eq 'Built Nova module: NovaModuleTools' -and $color -eq 'Green'
            }
            Should -Invoke Write-Message -Times 1 -ParameterFilter {
                $Text -eq 'Next steps:'
            }
            Should -Invoke Write-Message -Times 1 -ParameterFilter {
                $Text -eq 'Invoke-NovaTest'
            }
            Should -Invoke Write-Message -Times 1 -ParameterFilter {
                $Text -eq 'Test-NovaBuild'
            }
        } finally {
            Remove-Variable -Name steps -Scope Global -ErrorAction SilentlyContinue
        }
    }

    It 'uses the shared module update notification before the optional CI import step and reports the refreshed session' {
        $global:steps = @()
        try {
            $workflowContext = [pscustomobject]@{
                ProjectInfo = [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                    FailOnDuplicateFunctionNames = $true
                }
                ContinuousIntegrationRequested = $true
            }

            Mock Assert-NovaPublicFunctionFileLayout {$global:steps += 'public-layout'}
            Mock Reset-ProjectDist {$global:steps += 'reset'}
            Mock Build-Module {$global:steps += 'module'}
            Mock Assert-BuiltModuleHasNoDuplicateFunctionName {$global:steps += 'duplicates'}
            Mock Build-Manifest {$global:steps += 'manifest'}
            Mock Build-Help {$global:steps += 'help'}
            Mock Copy-ProjectResource {$global:steps += 'resources'}
            Mock Invoke-NovaModuleUpdateNotificationSafely {$global:steps += 'notification'}
            Mock Import-NovaBuiltModuleForCi {$global:steps += 'ci'}
            Mock Write-Message {}
            Mock Write-Progress {}

            Invoke-NovaBuildWorkflow -WorkflowContext $workflowContext

            $global:steps -join ',' | Should -Be 'public-layout,reset,module,duplicates,manifest,help,resources,notification,ci'
            Should -Invoke Import-NovaBuiltModuleForCi -Times 1
            Should -Invoke Write-Progress -Times 10
            Should -Invoke Write-Progress -Times 1 -ParameterFilter {
                $Status -eq 'Refreshing the current session with the built module' -and $PercentComplete -eq 98
            }
            Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
            Should -Invoke Write-Message -Times 3
        } finally {
            Remove-Variable -Name steps -Scope Global -ErrorAction SilentlyContinue
        }
    }

    It 'does not call the local result helper after the CI import refreshes the module session' {
        $global:steps = @()
        try {
            $workflowContext = [pscustomobject]@{
                ProjectInfo = [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                    FailOnDuplicateFunctionNames = $true
                }
                ContinuousIntegrationRequested = $true
            }

            Mock Assert-NovaPublicFunctionFileLayout {$global:steps += 'public-layout'}
            Mock Reset-ProjectDist {$global:steps += 'reset'}
            Mock Build-Module {$global:steps += 'module'}
            Mock Assert-BuiltModuleHasNoDuplicateFunctionName {$global:steps += 'duplicates'}
            Mock Build-Manifest {$global:steps += 'manifest'}
            Mock Build-Help {$global:steps += 'help'}
            Mock Copy-ProjectResource {$global:steps += 'resources'}
            Mock Invoke-NovaModuleUpdateNotificationSafely {$global:steps += 'notification'}
            Mock Import-NovaBuiltModuleForCi {
                $global:steps += 'ci'
                Remove-Item Function:\Write-NovaBuildWorkflowResult -ErrorAction SilentlyContinue
            }
            Mock Write-Message {}
            Mock Write-Progress {}

            { Invoke-NovaBuildWorkflow -WorkflowContext $workflowContext } | Should -Not -Throw

            $global:steps -join ',' | Should -Be 'public-layout,reset,module,duplicates,manifest,help,resources,notification,ci'
        } finally {
            Remove-Variable -Name steps -Scope Global -ErrorAction SilentlyContinue
        }
    }
}
