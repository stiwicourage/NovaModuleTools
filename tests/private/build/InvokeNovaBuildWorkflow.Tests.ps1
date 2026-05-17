BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/build/InvokeNovaBuildWorkflow.ps1')

    function Assert-NovaPublicFunctionFileLayout {param($ProjectInfo, [switch]$OverrideWarningRequested)}
    function Reset-ProjectDist {param($ProjectInfo)}
    function Build-Module {param($ProjectInfo)}
    function Assert-BuiltModuleHasNoDuplicateFunctionName {param($ProjectInfo)}
    function Build-Manifest {param($ProjectInfo)}
    function Build-Help {param($ProjectInfo)}
    function Copy-ProjectResource {param($ProjectInfo)}
    function Invoke-NovaModuleUpdateNotificationSafely {}
    function Import-NovaBuiltModuleForCi {param($ProjectInfo)}
}

Describe 'Invoke-NovaBuildWorkflow' {
    It 'uses the shared module update notification before the optional CI import step' {
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

            Invoke-NovaBuildWorkflow -WorkflowContext $workflowContext

            $global:steps -join ',' | Should -Be 'public-layout,reset,module,duplicates,manifest,help,resources,notification,ci'
            Assert-MockCalled Invoke-NovaModuleUpdateNotificationSafely -Times 1
            Assert-MockCalled Import-NovaBuiltModuleForCi -Times 1
        } finally {
            Remove-Variable -Name steps -Scope Global -ErrorAction SilentlyContinue
        }
    }
}
