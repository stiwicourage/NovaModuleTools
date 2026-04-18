function Get-NovaPesterOutputOptionOverride {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$PesterConfig,
        [Parameter(Mandatory)][hashtable]$BoundParameters,
        [string]$OutputVerbosity,
        [string]$OutputRenderMode
    )

    if ($PesterConfig.PSObject.Properties.Name -notcontains 'Output') {
        return $null
    }

    return [pscustomobject]@{
        Verbosity = if ( $BoundParameters.ContainsKey('OutputVerbosity')) {
            $OutputVerbosity
        }
        else {
            $null
        }
        RenderMode = if ( $BoundParameters.ContainsKey('OutputRenderMode')) {
            $OutputRenderMode
        }
        else {
            'Plaintext'
        }
    }
}


