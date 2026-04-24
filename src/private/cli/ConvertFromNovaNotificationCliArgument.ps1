function ConvertFrom-NovaNotificationCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    $Arguments = ConvertTo-NovaCliArgumentArray -BoundParameters $PSBoundParameters -Arguments $Arguments
    if ($Arguments.Count -eq 0) {
        return 'status'
    }

    if ($Arguments.Count -ne 1) {
        Stop-NovaOperation -Message "Unsupported 'nova notification' usage. Use 'nova notification', 'nova notification -enable', or 'nova notification -disable'." -ErrorId 'Nova.Validation.UnsupportedNotificationCliUsage' -Category InvalidArgument -TargetObject $Arguments
    }

    switch -Regex ($Arguments[0]) {
        '^(--enable|-Enable)$' {
            return 'enable'
        }
        '^(--disable|-Disable)$' {
            return 'disable'
        }
        default {
            Stop-NovaOperation -Message "Unknown argument: $( $Arguments[0] )" -ErrorId 'Nova.Validation.UnknownCliArgument' -Category InvalidArgument -TargetObject $Arguments[0]
        }
    }
}
