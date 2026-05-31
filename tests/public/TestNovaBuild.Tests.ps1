BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/public/TestNovaBuild.ps1')

    function Get-NovaDynamicOverrideWarningParameterDictionary {
        $dictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
        $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
        $attributeCollection.Add([System.Management.Automation.ParameterAttribute]::new())
        $runtimeParameter = [System.Management.Automation.RuntimeDefinedParameter]::new('OverrideWarning', [switch], $attributeCollection)
        $dictionary.Add('OverrideWarning', $runtimeParameter)
        return $dictionary
    }

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

Describe 'Test-NovaBuild' {
    BeforeEach {
        $script:testOption = $null
        $script:boundParameters = $null
        $script:shouldRun = $null
    }

    It 'forwards build-validation options to the workflow context' {
        Test-NovaBuild -OverrideWarning -TagFilter 'fast' -OutputVerbosity 'Detailed'

        $script:testOption.TestMode | Should -Be 'BuildValidation'
        $script:testOption.TagFilter | Should -Be @('fast')
        $script:testOption.OutputVerbosity | Should -Be 'Detailed'
        $script:boundParameters.OverrideWarning | Should -BeTrue
        $script:shouldRun | Should -BeTrue
    }

    It 'invokes the workflow with ShouldRun=$false when -WhatIf is set' {
        Test-NovaBuild -WhatIf | Out-Null

        $script:boundParameters.WhatIf | Should -BeTrue
        $script:shouldRun | Should -BeFalse
    }
}
