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
        $script:buildCalls = 0
        $script:testCalls = 0
        $script:versionCalls = 0
        $script:restoreCalls = 0
        $script:publishCalls = 0
        Mock Write-Message {}
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
        $script:testCalls | Should -Be 1
        $script:versionCalls | Should -Be 1
        $script:publishCalls | Should -Be 1
        $script:restoreCalls | Should -Be 1
        Assert-MockCalled Write-Progress -Times 6
        Assert-MockCalled Write-Message -Times 5
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Released Nova module: NovaModuleTools 1.0.0' -and $color -eq 'Green'
        }
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Get-NovaProjectInfo -Version'
        }
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
        $script:testCalls | Should -Be 0
        $script:restoreCalls | Should -Be 0
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Pre-release tests were skipped for this run.'
        }
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Get-NovaProjectInfo -Installed'
        }
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
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Release plan ready for NovaModuleTools -> 1.0.0' -and $color -eq 'Green'
        }
        Assert-MockCalled Write-Message -Times 1 -ParameterFilter {
            $Text -eq 'Run Invoke-NovaRelease without -WhatIf when you are ready to apply the release.'
        }
    }
}
