BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/TestNovaBuild.ps1')

    function New-NovaTestDynamicParameterDictionary {return New-Object 'System.Management.Automation.RuntimeDefinedParameterDictionary'}
    function Get-NovaTestWorkflowContext {param($TestOption, $BoundParameters)
        $script:testOption = $TestOption
        return [pscustomobject]@{Target='/proj'; Operation='Test'}
    }
    function Invoke-NovaTestWorkflow {param($WorkflowContext, [switch]$ShouldRun) $script:shouldRun = [bool]$ShouldRun}
}

Describe 'Test-NovaBuild' {
    BeforeEach {
        $script:testOption = $null
        $script:shouldRun = $null
    }

    It 'forwards filter and verbosity parameters to the workflow context' {
        Test-NovaBuild -TagFilter 'fast' -OutputVerbosity 'Detailed'
        $script:testOption.TagFilter | Should -Be @('fast')
        $script:testOption.OutputVerbosity | Should -Be 'Detailed'
        $script:shouldRun | Should -BeTrue
    }

    It 'invokes the workflow with ShouldRun=$false when -WhatIf is set' {
        Test-NovaBuild -WhatIf | Out-Null
        $script:shouldRun | Should -BeFalse
    }
}
