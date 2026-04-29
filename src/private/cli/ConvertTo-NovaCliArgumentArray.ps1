function ConvertTo-NovaCliArgumentArray {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$BoundParameters,
        [AllowNull()][string[]]$Arguments
    )

    $normalizedArguments = [System.Collections.Generic.List[string]]::new()
    if ( $BoundParameters.ContainsKey('Arguments')) {
        foreach ($argument in $Arguments) {
            $normalizedArguments.Add($argument)
        }
    }

    return ,$normalizedArguments.ToArray()
}
