BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/InvokeNovaPublishWorkflow.ps1')
    . (Join-Path $PSScriptRoot 'InvokeNovaPublishWorkflow.TestSupport.ps1')
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

Describe 'Test-NovaPublishWorkflowWhatIfEnabled' {
    It 'returns true when WorkflowParams.WhatIf is enabled' {
        $ctx = [pscustomobject]@{WorkflowParams = @{WhatIf = $true}}
        Test-NovaPublishWorkflowWhatIfEnabled -WorkflowContext $ctx | Should -BeTrue
    }

    It 'returns false when WorkflowParams.WhatIf is not enabled' {
        $ctx = [pscustomobject]@{WorkflowParams = @{}}
        Test-NovaPublishWorkflowWhatIfEnabled -WorkflowContext $ctx | Should -BeFalse
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
        Mock Write-Message {}
        Mock Write-Progress {}
    }

    It 'runs validation and publish, reports progress, and suggests how to verify repository publish' {
        Mock Invoke-NovaBuildValidation {$script:validationCalls += 1}
        $ctx = [pscustomobject]@{
            PublishParams = @{}
            PublishInvocation = [pscustomobject]@{Action = {param() $script:publishCalls += 1}; Target = 'PSGallery'; IsLocal = $false}
            LocalPublishActivation = $null
            ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
            WorkflowParams = @{}
            SkipTestsRequested = $false
            ContinuousIntegrationRequested = $false
        }
        Invoke-NovaPublishWorkflow -WorkflowContext $ctx -ShouldRun
        $script:validationCalls | Should -Be 1
        $script:publishCalls | Should -Be 1
        $script:localImportCalls | Should -Be 0
        Assert-MockCalled Write-Progress -Times 3
        Assert-MockCalled Write-Message -Times 4
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Published Nova module: NovaModuleTools' -and $color -eq 'Green'
        }
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Find-Module NovaModuleTools -Repository PSGallery'
        }
    }

    It 'imports the local published module, restores the built module in CI, and reports the result' {
        Mock Invoke-NovaBuildValidation {$script:validationCalls += 1}
        $ctx = [pscustomobject]@{
            PublishParams = @{}
            PublishInvocation = [pscustomobject]@{
                Action = {param() $script:publishCalls += 1}
                IsLocal = $true
                Target = '/modules'
                Parameters = [pscustomobject]@{ProjectInfo = [pscustomobject]@{ProjectName='Mod'}}
            }
            LocalPublishActivation = [pscustomobject]@{
                ManifestPath='/m/Mod.psd1'
                ImportAction = {param($ProjectName,$ManifestPath) $script:localImportCalls += 1}
            }
            ProjectInfo = [pscustomobject]@{ProjectName = 'Mod'}
            WorkflowParams = @{}
            SkipTestsRequested = $true
            ContinuousIntegrationRequested = $true
        }
        Invoke-NovaPublishWorkflow -WorkflowContext $ctx -ShouldRun
        $script:localImportCalls | Should -Be 1
        $script:ciImportCalls | Should -Be 1
        Assert-MockCalled Write-Progress -Times 5
        Assert-MockCalled Write-Message -Times 6
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Pre-publish tests were skipped for this run.'
        }
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'The published local module is loaded from /m/Mod.psd1.'
        }
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'The freshly built dist module is loaded again for later commands in this session.'
        }
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Get-NovaProjectInfo -Installed'
        }
    }

    It 'writes a publish plan summary in WhatIf mode without importing or restoring modules' {
        Mock Invoke-NovaBuildValidation {$script:validationCalls += 1}
        $ctx = [pscustomobject]@{
            PublishParams = @{WhatIf = $true}
            PublishInvocation = [pscustomobject]@{Action = {param() $script:publishCalls += 1}; Target = 'PSGallery'; IsLocal = $false}
            LocalPublishActivation = [pscustomobject]@{
                ManifestPath='/m/Mod.psd1'
                ImportAction = {param($ProjectName,$ManifestPath) $script:localImportCalls += 1}
            }
            ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
            WorkflowParams = @{WhatIf = $true}
            SkipTestsRequested = $false
            ContinuousIntegrationRequested = $true
        }

        Invoke-NovaPublishWorkflow -WorkflowContext $ctx

        $script:publishCalls | Should -Be 1
        $script:localImportCalls | Should -Be 0
        $script:ciImportCalls | Should -Be 0
        Assert-MockCalled Write-Message -Times 4
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Publish plan ready for NovaModuleTools' -and $color -eq 'Green'
        }
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Run Publish-NovaModule without -WhatIf when you are ready to publish the module.'
        }
    }
}
