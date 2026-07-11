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
        . (Join-Path $projectRoot 'src/private/release/InvokeNovaPublishWorkflow.ps1')
        $script:validationCalls = 0
        $script:publishCalls = 0
        $script:localImportCalls = 0
        $script:ciImportCalls = 0
        $script:messages = @()
        Set-Item -Path Function:\Write-Message -Value {
            param($Text, $color)
            $script:messages += [pscustomobject]@{
                Text = $Text
                Color = $color
            }
        }
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
        Should -Invoke Write-Progress -Times 3
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Building and testing publish output' -and $PercentComplete -eq 35
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Publishing to repository PSGallery' -and $PercentComplete -eq 75
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
        $script:messages.Count | Should -Be 4
        ($script:messages | Where-Object {$_.Text -eq 'Published Nova module: NovaModuleTools' -and $_.Color -eq 'Green'}).Count | Should -Be 1
        ($script:messages | Where-Object {$_.Text -eq 'Find-Module NovaModuleTools -Repository PSGallery'}).Count | Should -Be 1
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
        Should -Invoke Write-Progress -Times 5
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Importing the published local module' -and $PercentComplete -eq 90
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Refreshing the current session with the built module' -and $PercentComplete -eq 98
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
        $script:messages.Count | Should -Be 7
        ($script:messages | Where-Object {$_.Text -eq 'Pre-publish tests were skipped for this run.'}).Count | Should -Be 1
        ($script:messages | Where-Object {$_.Text -eq 'The published local module is loaded from /m/Mod.psd1.'}).Count | Should -Be 1
        ($script:messages | Where-Object {$_.Text -eq 'The freshly built dist module is loaded again for later commands in this session.'}).Count | Should -Be 1
        ($script:messages | Where-Object {$_.Text -eq 'Get-NovaProjectInfo -Installed'}).Count | Should -Be 1
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
        $script:messages.Count | Should -Be 4
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Previewing publish to repository PSGallery' -and $PercentComplete -eq 75
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
        ($script:messages | Where-Object {$_.Text -eq 'Publish plan ready for NovaModuleTools' -and $_.Color -eq 'Green'}).Count | Should -Be 1
        ($script:messages | Where-Object {$_.Text -eq 'Run Publish-NovaModule without -WhatIf when you are ready to publish the module.'}).Count | Should -Be 1
    }

    It 'still writes the result after the local publish import refreshes the module session' {
        $originalStatusMessage = (Get-Command -Name Get-NovaPublishWorkflowStatusMessage -CommandType Function).ScriptBlock
        $originalNextStepLine = (Get-Command -Name Get-NovaPublishWorkflowNextStepLine -CommandType Function).ScriptBlock
        Mock Invoke-NovaBuildValidation {$script:validationCalls += 1}
        $ctx = [pscustomobject]@{
            PublishParams = @{}
            PublishInvocation = [pscustomobject]@{
                Action = {param() $script:publishCalls += 1}
                IsLocal = $true
                Target = '/modules'
                Parameters = [pscustomobject]@{ProjectInfo = [pscustomobject]@{ProjectName='NovaModuleTools'}}
            }
            LocalPublishActivation = [pscustomobject]@{
                ManifestPath='/m/NovaModuleTools.psd1'
                ImportAction = {
                    param($ProjectName,$ManifestPath)
                    $script:localImportCalls += 1
                    Remove-Item Function:\Get-NovaPublishWorkflowStatusMessage -ErrorAction SilentlyContinue
                    Remove-Item Function:\Get-NovaPublishWorkflowNextStepLine -ErrorAction SilentlyContinue
                }
            }
            ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
            WorkflowParams = @{}
            SkipTestsRequested = $true
            ContinuousIntegrationRequested = $false
        }

        try {
            { Invoke-NovaPublishWorkflow -WorkflowContext $ctx -ShouldRun } | Should -Not -Throw

            $script:localImportCalls | Should -Be 1
            ($script:messages | Where-Object {$_.Text -eq 'Published Nova module: NovaModuleTools' -and $_.Color -eq 'Green'}).Count | Should -Be 1
            ($script:messages | Where-Object {$_.Text -eq 'The published local module is loaded from /m/NovaModuleTools.psd1.'}).Count | Should -Be 1
        } finally {
            Set-Item -Path Function:\Get-NovaPublishWorkflowStatusMessage -Value $originalStatusMessage
            Set-Item -Path Function:\Get-NovaPublishWorkflowNextStepLine -Value $originalNextStepLine
        }
    }

    It 'still writes the result after the CI restore refreshes the module session' {
        $originalStatusMessage = (Get-Command -Name Get-NovaPublishWorkflowStatusMessage -CommandType Function).ScriptBlock
        $originalNextStepLine = (Get-Command -Name Get-NovaPublishWorkflowNextStepLine -CommandType Function).ScriptBlock
        Mock Invoke-NovaBuildValidation {$script:validationCalls += 1}
        $ctx = [pscustomobject]@{
            PublishParams = @{}
            PublishInvocation = [pscustomobject]@{
                Action = {param() $script:publishCalls += 1}
                IsLocal = $false
                Target = 'PSGallery'
            }
            LocalPublishActivation = $null
            ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
            WorkflowParams = @{}
            SkipTestsRequested = $false
            ContinuousIntegrationRequested = $true
        }

        Mock Import-NovaBuiltModuleForCi {
            $script:ciImportCalls += 1
            Remove-Item Function:\Get-NovaPublishWorkflowStatusMessage -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-NovaPublishWorkflowNextStepLine -ErrorAction SilentlyContinue
        }

        try {
            { Invoke-NovaPublishWorkflow -WorkflowContext $ctx -ShouldRun } | Should -Not -Throw

            $script:ciImportCalls | Should -Be 1
            ($script:messages | Where-Object {$_.Text -eq 'Published Nova module: NovaModuleTools' -and $_.Color -eq 'Green'}).Count | Should -Be 1
        } finally {
            Set-Item -Path Function:\Get-NovaPublishWorkflowStatusMessage -Value $originalStatusMessage
            Set-Item -Path Function:\Get-NovaPublishWorkflowNextStepLine -Value $originalNextStepLine
        }
    }
}

Describe 'Get-NovaPublishWorkflowPropertyValue' {
    It 'returns the value from a dictionary when the key exists' {
        $dict = @{Name = 'test-value'}
        Get-NovaPublishWorkflowPropertyValue -InputObject $dict -Name 'Name' | Should -Be 'test-value'
    }

    It 'returns null from a dictionary when the key does not exist' {
        $dict = @{Other = 'test-value'}
        Get-NovaPublishWorkflowPropertyValue -InputObject $dict -Name 'Missing' | Should -BeNullOrEmpty
    }

    It 'returns null when a PSObject does not have the named property' {
        $obj = [pscustomobject]@{Exists = 'yes'}
        Get-NovaPublishWorkflowPropertyValue -InputObject $obj -Name 'Missing' | Should -BeNullOrEmpty
    }
}
