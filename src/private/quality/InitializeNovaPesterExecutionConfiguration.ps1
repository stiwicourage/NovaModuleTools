function Initialize-NovaPesterExecutionConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$PesterConfig,
        [Parameter(Mandatory)][hashtable]$BoundParameters,
        [string]$OutputVerbosity,
        [string]$OutputRenderMode
    )

    $outputOptionOverrides = Get-NovaPesterOutputOptionOverride -PesterConfig $PesterConfig -BoundParameters $BoundParameters -OutputVerbosity $OutputVerbosity -OutputRenderMode $OutputRenderMode
    if ($null -ne $outputOptionOverrides) {
        if ($null -ne $outputOptionOverrides.Verbosity) {
            $PesterConfig.Output.Verbosity = $outputOptionOverrides.Verbosity
        }

        if ($null -ne $outputOptionOverrides.RenderMode) {
            $PesterConfig.Output.RenderMode = $outputOptionOverrides.RenderMode
        }
    }

    if ($PesterConfig.TestResult.PSObject.Properties.Name -contains 'Enabled') {
        $PesterConfig.TestResult.Enabled = $false
    }
}
