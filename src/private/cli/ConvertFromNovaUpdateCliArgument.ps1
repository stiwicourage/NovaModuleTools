function ConvertFrom-NovaUpdateCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    $Arguments = ConvertTo-NovaCliArgumentArray -BoundParameters $PSBoundParameters -Arguments $Arguments
    if ($Arguments.Count -eq 0) {
        return @{}
    }

    Stop-NovaOperation -Message "Unsupported 'nova update' usage. Use 'nova update'." -ErrorId 'Nova.Validation.UnsupportedUpdateCliUsage' -Category InvalidArgument -TargetObject $Arguments
}
