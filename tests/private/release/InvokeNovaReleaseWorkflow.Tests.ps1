BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/InvokeNovaReleaseWorkflow.ps1')
    . (Join-Path $PSScriptRoot 'InvokeNovaReleaseWorkflow.TestSupport.ps1')
}

Describe 'Get-NovaReleaseNestedWorkflowParameterMap' {
    It 'copies workflow params and injects ContinuousIntegration when requested' {
        $m = Get-NovaReleaseNestedWorkflowParameterMap -WorkflowParams @{Path='/p'} -ContinuousIntegrationRequested
        $m.Path | Should -Be '/p'
        $m.ContinuousIntegration | Should -BeTrue
    }
    It 'omits ContinuousIntegration when not requested' {
        $m = Get-NovaReleaseNestedWorkflowParameterMap -WorkflowParams @{X=1}
        $m.ContainsKey('ContinuousIntegration') | Should -BeFalse
    }
}

Describe 'Get-NovaReleaseBuildWorkflowParameterMap' {
    It 'delegates to Get-NovaBuildCommandParameterMap with OverrideWarning' {
        $m = Get-NovaReleaseBuildWorkflowParameterMap -WorkflowParams @{Path='/p'} -OverrideWarningRequested
        $m.OverrideWarning | Should -BeTrue
    }
}

Describe 'Get-NovaReleaseWorkflowResultVersion' {
    It 'returns null when no version result is available' {
        Get-NovaReleaseWorkflowResultVersion -VersionResult $null | Should -BeNullOrEmpty
    }

    It 'prefers NewVersion when the version result exposes it' {
        Get-NovaReleaseWorkflowResultVersion -VersionResult ([pscustomobject]@{NewVersion = '1.2.3'; Version = '1.2.2'}) | Should -Be '1.2.3'
    }

    It 'falls back to Version when NewVersion is not present' {
        Get-NovaReleaseWorkflowResultVersion -VersionResult ([pscustomobject]@{Version = '1.2.3'}) | Should -Be '1.2.3'
    }

    It 'returns null when the version result has no version-like properties' {
        Get-NovaReleaseWorkflowResultVersion -VersionResult ([pscustomobject]@{Other = 'x'}) | Should -BeNullOrEmpty
    }
}

Describe 'Get-NovaReleaseWorkflowStatusMessage' {
    It 'returns a plan-ready message without a version in WhatIf mode' {
        Get-NovaReleaseWorkflowStatusMessage -ProjectInfo ([pscustomobject]@{ProjectName = 'NovaModuleTools'}) -WhatIfEnabled | Should -Be 'Release plan ready for NovaModuleTools'
    }

    It 'returns a released message without a version when no version was resolved' {
        Get-NovaReleaseWorkflowStatusMessage -ProjectInfo ([pscustomobject]@{ProjectName = 'NovaModuleTools'}) | Should -Be 'Released Nova module: NovaModuleTools'
    }
}

Describe 'Test-NovaReleaseWorkflowShouldRestoreBuiltModule' {
    It 'returns true when CI is on and WhatIf is not set' {
        Test-NovaReleaseWorkflowShouldRestoreBuiltModule -WorkflowParams @{} -ContinuousIntegrationRequested | Should -BeTrue
    }
    It 'returns false when WhatIf is set' {
        Test-NovaReleaseWorkflowShouldRestoreBuiltModule -WorkflowParams @{WhatIf=$true} -ContinuousIntegrationRequested | Should -BeFalse
    }
    It 'returns false when CI is off' {
        Test-NovaReleaseWorkflowShouldRestoreBuiltModule -WorkflowParams @{} | Should -BeFalse
    }
}

Describe 'Invoke-NovaReleaseWorkflow' {
    BeforeEach {
        . (Join-Path $projectRoot 'src/private/release/InvokeNovaReleaseWorkflow.ps1')
        $script:buildCalls = 0
        $script:unitTestCalls = 0
        $script:integrationTestCalls = 0
        $script:versionCalls = 0
        $script:restoreCalls = 0
        $script:publishCalls = 0
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

    It 'builds, tests, updates version, builds again, publishes, restores in CI, and reports the result' {
        $ctx = [pscustomobject]@{
            WorkflowParams = @{}
            PublishParams = @{}
            PublishInvocation = [pscustomobject]@{Action = {param() $script:publishCalls += 1}; Target = 'PSGallery'; IsLocal = $false}
            ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
            ContinuousIntegrationRequested = $true
            SkipTestsRequested = $false
            OverrideWarningRequested = $false
        }
        $r = Invoke-NovaReleaseWorkflow -WorkflowContext $ctx
        $r.Version | Should -Be '1.0.0'
        $script:buildCalls | Should -Be 2
        $script:unitTestCalls | Should -Be 1
        $script:integrationTestCalls | Should -Be 1
        $script:versionCalls | Should -Be 1
        $script:publishCalls | Should -Be 1
        $script:restoreCalls | Should -Be 1
        Should -Invoke Write-Progress -Times 6
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Building the current project state' -and $PercentComplete -eq 15
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Running pre-release tests' -and $PercentComplete -eq 35
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Updating the project version' -and $PercentComplete -eq 55
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Rebuilding release output' -and $PercentComplete -eq 75
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Publishing release to repository PSGallery' -and $PercentComplete -eq 90
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Refreshing the current session with the built module' -and $PercentComplete -eq 98
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
        $script:messages.Count | Should -Be 5
        ($script:messages | Where-Object {$_.Text -eq 'Released Nova module: NovaModuleTools 1.0.0' -and $_.Color -eq 'Green'}).Count | Should -Be 1
        ($script:messages | Where-Object {$_.Text -eq 'Get-NovaProjectInfo -Version'}).Count | Should -Be 1
    }

    It 'skips tests when SkipTestsRequested and skips restore when not CI' {
        $ctx = [pscustomobject]@{
            WorkflowParams = @{}
            PublishParams = @{}
            PublishInvocation = [pscustomobject]@{Action = {param() $script:publishCalls += 1}; Target = '/modules'; IsLocal = $true}
            ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
            SkipTestsRequested = $true
        }
        $null = Invoke-NovaReleaseWorkflow -WorkflowContext $ctx
        $script:unitTestCalls | Should -Be 0
        $script:integrationTestCalls | Should -Be 0
        $script:restoreCalls | Should -Be 0
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Publishing release to the local module path' -and $PercentComplete -eq 90
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
        ($script:messages | Where-Object {$_.Text -eq 'Pre-release tests were skipped for this run.'}).Count | Should -Be 1
        ($script:messages | Where-Object {$_.Text -eq 'Get-NovaProjectInfo -Installed'}).Count | Should -Be 1
    }

    It 'writes a release plan summary in WhatIf mode without restoring the built module' {
        $ctx = [pscustomobject]@{
            WorkflowParams = @{WhatIf = $true}
            PublishParams = @{}
            PublishInvocation = [pscustomobject]@{Action = {param() $script:publishCalls += 1}; Target = 'PSGallery'; IsLocal = $false}
            ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
            ContinuousIntegrationRequested = $true
            SkipTestsRequested = $false
        }

        $null = Invoke-NovaReleaseWorkflow -WorkflowContext $ctx

        $script:restoreCalls | Should -Be 0
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Planning the next release version' -and $PercentComplete -eq 55
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {
            $Status -eq 'Previewing publish to repository PSGallery' -and $PercentComplete -eq 90
        }
        Should -Invoke Write-Progress -Times 1 -ParameterFilter {$Completed}
        ($script:messages | Where-Object {$_.Text -eq 'Release plan ready for NovaModuleTools -> 1.0.0' -and $_.Color -eq 'Green'}).Count | Should -Be 1
        ($script:messages | Where-Object {$_.Text -eq 'Run Invoke-NovaRelease without -WhatIf when you are ready to apply the release.'}).Count | Should -Be 1
    }

    It 'still writes the result after the CI restore refreshes the module session' {
        $originalStatusMessage = (Get-Command -Name Get-NovaReleaseWorkflowStatusMessage -CommandType Function).ScriptBlock
        $originalNextStepLine = (Get-Command -Name Get-NovaReleaseWorkflowNextStepLine -CommandType Function).ScriptBlock
        $ctx = [pscustomobject]@{
            WorkflowParams = @{}
            PublishParams = @{}
            PublishInvocation = [pscustomobject]@{Action = {param() $script:publishCalls += 1}; Target = 'PSGallery'; IsLocal = $false}
            ProjectInfo = [pscustomobject]@{ProjectName = 'NovaModuleTools'}
            ContinuousIntegrationRequested = $true
            SkipTestsRequested = $false
            OverrideWarningRequested = $false
        }

        Mock Import-NovaBuiltModuleForCi {
            $script:restoreCalls += 1
            Remove-Item Function:\Get-NovaReleaseWorkflowStatusMessage -ErrorAction SilentlyContinue
            Remove-Item Function:\Get-NovaReleaseWorkflowNextStepLine -ErrorAction SilentlyContinue
        }

        try {
            { Invoke-NovaReleaseWorkflow -WorkflowContext $ctx } | Should -Not -Throw

            $script:restoreCalls | Should -Be 1
            ($script:messages | Where-Object {$_.Text -eq 'Released Nova module: NovaModuleTools 1.0.0' -and $_.Color -eq 'Green'}).Count | Should -Be 1
        } finally {
            Set-Item -Path Function:\Get-NovaReleaseWorkflowStatusMessage -Value $originalStatusMessage
            Set-Item -Path Function:\Get-NovaReleaseWorkflowNextStepLine -Value $originalNextStepLine
        }
    }
}
