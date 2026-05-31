function Invoke-NovaTest {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [string[]]$TagFilter,
        [string[]]$ExcludeTagFilter,
        [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
        [string]$OutputVerbosity,
        [ValidateSet('Auto', 'Ansi')]
        [string]$OutputRenderMode
    )

    dynamicparam {
        $dictionary = Get-NovaDynamicOverrideWarningParameterDictionary
        $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
        $attributeCollection.Add([System.Management.Automation.ParameterAttribute]::new())
        $runtimeParameter = [System.Management.Automation.RuntimeDefinedParameter]::new('PesterConfigurationOverride', [hashtable], $attributeCollection)
        $dictionary.Add('PesterConfigurationOverride', $runtimeParameter)
        return $dictionary
    }

    end {
        $pesterConfigurationOverride = $null
        if ($PSBoundParameters.ContainsKey('PesterConfigurationOverride')) {
            $pesterConfigurationOverride = [hashtable]$PSBoundParameters.PesterConfigurationOverride
        }

        $workflowContext = Get-NovaTestWorkflowContext -TestOption @{
            TestMode = 'Unit'
            TagFilter = $TagFilter
            ExcludeTagFilter = $ExcludeTagFilter
            OutputVerbosity = $OutputVerbosity
            OutputRenderMode = $OutputRenderMode
            PesterConfigurationOverride = $pesterConfigurationOverride
        } -BoundParameters $PSBoundParameters

        $shouldRun = $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Operation)
        if (-not $shouldRun -and -not $WhatIfPreference) {
            return
        }

        Invoke-NovaTestWorkflow -WorkflowContext $workflowContext -ShouldRun:$shouldRun
    }
}
