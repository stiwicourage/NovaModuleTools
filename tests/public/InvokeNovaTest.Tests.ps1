BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/InvokeNovaTest.ps1')

    function Get-NovaTestWorkflowContext {
        param($TestOption, $BoundParameters)

        $script:testOption = $TestOption
        $script:boundParameters = $BoundParameters
        return [pscustomobject]@{Target = '/proj'; Operation = 'Test'}
    }

    function Invoke-NovaTestWorkflow {
        param($WorkflowContext, [switch]$ShouldRun)

        $script:shouldRun = [bool]$ShouldRun
    }
}

Describe 'Invoke-NovaTest' {
    BeforeEach {
        $script:testOption = $null
        $script:boundParameters = $null
        $script:shouldRun = $null
    }

    It 'forwards unit-test options to the workflow context' {
        Invoke-NovaTest -TagFilter 'fast' -ExcludeTagFilter 'integration' -OutputVerbosity 'Detailed'

        $script:testOption.TestMode | Should -Be 'Unit'
        $script:testOption.TagFilter | Should -Be @('fast')
        $script:testOption.ExcludeTagFilter | Should -Be @('integration')
        $script:testOption.OutputVerbosity | Should -Be 'Detailed'
        $script:shouldRun | Should -BeTrue
    }

    It 'invokes the workflow with ShouldRun=$false when -WhatIf is set' {
        Invoke-NovaTest -WhatIf | Out-Null

        $script:boundParameters.WhatIf | Should -BeTrue
        $script:shouldRun | Should -BeFalse
    }
}
