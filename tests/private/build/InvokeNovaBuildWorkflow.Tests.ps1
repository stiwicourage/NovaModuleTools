BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
    $script:moduleName = (Get-Content -LiteralPath (Join-Path $script:repoRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
    $script:distModuleDir = Join-Path $script:repoRoot "dist/$script:moduleName"

    if (-not (Test-Path -LiteralPath $script:distModuleDir)) {
        throw "Expected built $script:moduleName module at: $script:distModuleDir. Run Invoke-NovaBuild in the repo root first."
    }

    Remove-Module $script:moduleName -ErrorAction SilentlyContinue
    Import-Module $script:distModuleDir -Force
}

Describe 'Invoke-NovaBuildWorkflow' {
    It 'uses the shared module update notification before the optional CI import step' {
        InModuleScope $script:moduleName {
            $script:steps = @()
            $workflowContext = [pscustomobject]@{
                ProjectInfo = [pscustomobject]@{
                    ProjectName = 'NovaModuleTools'
                    OutputModuleDir = '/tmp/dist/NovaModuleTools'
                    FailOnDuplicateFunctionNames = $true
                }
                ContinuousIntegrationRequested = $true
            }

            Mock Assert-NovaPublicFunctionFileLayout {$script:steps += 'public-layout'}
            Mock Reset-ProjectDist {$script:steps += 'reset'}
            Mock Build-Module {$script:steps += 'module'}
            Mock Assert-BuiltModuleHasNoDuplicateFunctionName {$script:steps += 'duplicates'}
            Mock Build-Manifest {$script:steps += 'manifest'}
            Mock Build-Help {$script:steps += 'help'}
            Mock Copy-ProjectResource {$script:steps += 'resources'}
            Mock Invoke-NovaModuleUpdateNotificationSafely {$script:steps += 'notification'}
            Mock Import-NovaBuiltModuleForCi {$script:steps += 'ci'}

            Invoke-NovaBuildWorkflow -WorkflowContext $workflowContext

            $script:steps -join ',' | Should -Be 'public-layout,reset,module,duplicates,manifest,help,resources,notification,ci'
            Assert-MockCalled Invoke-NovaModuleUpdateNotificationSafely -Times 1
            Assert-MockCalled Import-NovaBuiltModuleForCi -Times 1
        }
    }
}

