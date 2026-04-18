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
        throw "Unsupported 'nova notification' usage. Use 'nova notification', 'nova notification -enable', or 'nova notification -disable'."
    }

    switch -Regex ($Arguments[0]) {
        '^(--enable|-Enable)$' {
            return 'enable'
        }
        '^(--disable|-Disable)$' {
            return 'disable'
        }
        default {
            throw "Unknown argument: $( $Arguments[0] )"
        }
    }
}

