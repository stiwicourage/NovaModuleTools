BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/InvokeNovaPublishWorkflow.ps1')
    function Import-NovaBuiltModuleForCi {param($ProjectInfo) $script:ciImportCalls += 1}
    function Invoke-NovaBuildValidation {param($WorkflowContext) $script:validationCalls += 1}
}

Describe 'Test-NovaPublishWorkflowShouldImportLocalModule' {
    It 'returns true when ShouldRun and LocalPublishActivation is set' {
        $ctx = [pscustomobject]@{LocalPublishActivation = [pscustomobject]@{}}
        Test-NovaPublishWorkflowShouldImportLocalModule -WorkflowContext $ctx -ShouldRun | Should -BeTrue
    }
    It 'returns false when LocalPublishActivation is null' {
        $ctx = [pscustomobject]@{LocalPublishActivation = $null}
        Test-NovaPublishWorkflowShouldImportLocalModule -WorkflowContext $ctx -ShouldRun | Should -BeFalse
    }
    It 'returns false when ShouldRun is not set' {
        $ctx = [pscustomobject]@{LocalPublishActivation = [pscustomobject]@{}}
        Test-NovaPublishWorkflowShouldImportLocalModule -WorkflowContext $ctx | Should -BeFalse
    }
}

Describe 'Invoke-NovaPublishWorkflowCiRestore' {
    It 'invokes the importer when ShouldRun and CI requested' {
        $script:calls = 0
        $action = {param($ProjectInfo) $script:calls += 1}
        Invoke-NovaPublishWorkflowCiRestore -WorkflowContext ([pscustomobject]@{ProjectInfo='x'}) -ShouldRun -ContinuousIntegrationRequested -ImportBuiltModuleForCiAction $action
        $script:calls | Should -Be 1
    }
    It 'does not invoke the importer when CI is off' {
        $script:calls = 0
        $action = {param($ProjectInfo) $script:calls += 1}
        Invoke-NovaPublishWorkflowCiRestore -WorkflowContext ([pscustomobject]@{ProjectInfo='x'}) -ShouldRun -ImportBuiltModuleForCiAction $action
        $script:calls | Should -Be 0
    }
}

Describe 'Invoke-NovaPublishWorkflow' {
    BeforeEach {
        $script:validationCalls = 0
        $script:publishCalls = 0
        $script:localImportCalls = 0
        $script:ciImportCalls = 0
    }

    It 'runs validation and publish; skips local import when activation is null' {
        Mock Invoke-NovaBuildValidation {$script:validationCalls += 1}
        $ctx = [pscustomobject]@{
            PublishParams = @{}
            PublishInvocation = [pscustomobject]@{Action = {param() $script:publishCalls += 1}}
            LocalPublishActivation = $null
            ProjectInfo = [pscustomobject]@{}
            ContinuousIntegrationRequested = $false
        }
        Invoke-NovaPublishWorkflow -WorkflowContext $ctx -ShouldRun
        $script:validationCalls | Should -Be 1
        $script:publishCalls | Should -Be 1
        $script:localImportCalls | Should -Be 0
    }

    It 'imports local published module when LocalPublishActivation is set' {
        Mock Invoke-NovaBuildValidation {$script:validationCalls += 1}
        $ctx = [pscustomobject]@{
            PublishParams = @{}
            PublishInvocation = [pscustomobject]@{
                Action = {param() $script:publishCalls += 1}
                Parameters = [pscustomobject]@{ProjectInfo = [pscustomobject]@{ProjectName='Mod'}}
            }
            LocalPublishActivation = [pscustomobject]@{
                ManifestPath='/m/Mod.psd1'
                ImportAction = {param($ProjectName,$ManifestPath) $script:localImportCalls += 1}
            }
            ProjectInfo = [pscustomobject]@{}
            ContinuousIntegrationRequested = $false
        }
        Invoke-NovaPublishWorkflow -WorkflowContext $ctx -ShouldRun
        $script:localImportCalls | Should -Be 1
    }
}
