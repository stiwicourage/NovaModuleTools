function ConvertFrom-NovaUpdateCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    $Arguments = ConvertTo-NovaCliArgumentArray -BoundParameters $PSBoundParameters -Arguments $Arguments
    if ($Arguments.Count -eq 0) {
        return @{}
    }

    throw "Unsupported 'nova update' usage. Use 'nova update'."
}
