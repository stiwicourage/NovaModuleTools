function Add-NovaCliOptionValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Options,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Value
    )

    $existingValue = @()
    if ( $Options.ContainsKey($Name)) {
        $existingValue = @($Options[$Name])
    }

    $Options[$Name] = @($existingValue + $Value)
}

