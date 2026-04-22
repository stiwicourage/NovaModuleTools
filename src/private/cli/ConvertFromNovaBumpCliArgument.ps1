function ConvertFrom-NovaBumpCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    $Arguments = ConvertTo-NovaCliArgumentArray -BoundParameters $PSBoundParameters -Arguments $Arguments
    $options = @{}

    foreach ($token in $Arguments) {
        switch -Regex ($token) {
            '^(--preview|-Preview)$' {
                $options.Preview = $true
            }
            default {
                throw "Unknown argument: $token"
            }
        }
    }

    return $options
}

