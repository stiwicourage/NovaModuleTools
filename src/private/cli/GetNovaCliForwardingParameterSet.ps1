function Get-NovaCliForwardingParameterSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$BoundParameters,
        [switch]$IncludeShouldProcess
    )

    $parameters = @{}
    if ( $BoundParameters.ContainsKey('Verbose')) {
        $parameters.Verbose = $true
    }

    if ($IncludeShouldProcess) {
        if ($WhatIfPreference) {
            $parameters.WhatIf = $true
        }

        if ( $BoundParameters.ContainsKey('Confirm')) {
            $parameters.Confirm = [bool]$BoundParameters.Confirm
        }
    }

    return $parameters
}


