BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/release/InvokeNovaReleaseWorkflow.ps1')
    function Get-NovaBuildCommandParameterMap {param([hashtable]$WorkflowParams,[switch]$OverrideWarningRequested) $map=@{}+$WorkflowParams; if($OverrideWarningRequested){$map.OverrideWarning=$true}; return $map}
    function Invoke-NovaBuild {param() $script:buildCalls += 1}
    function Test-NovaBuild {param() $script:testCalls += 1}
    function Update-NovaModuleVersion {param() $script:versionCalls += 1; return [pscustomobject]@{Version='1.0.0'}}
    function Import-NovaBuiltModuleForCi {param($ProjectInfo) $script:restoreCalls += 1}
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
    }

    It 'builds, tests, updates version, builds again, publishes, and restores in CI' {
        $ctx = [pscustomobject]@{
            WorkflowParams = @{}
            PublishParams = @{}
            PublishInvocation = [pscustomobject]@{Action = {param() $script:publishCalls += 1}}
            ProjectInfo = [pscustomobject]@{}
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
    }

    It 'skips tests when SkipTestsRequested and skips restore when not CI' {
        $ctx = [pscustomobject]@{
            WorkflowParams = @{}
            PublishParams = @{}
            PublishInvocation = [pscustomobject]@{Action = {param() $script:publishCalls += 1}}
            ProjectInfo = [pscustomobject]@{}
            SkipTestsRequested = $true
        }
        $null = Invoke-NovaReleaseWorkflow -WorkflowContext $ctx
        $script:testCalls | Should -Be 0
        $script:restoreCalls | Should -Be 0
    }
}
