function ConvertFrom-NovaTestCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    $Arguments = ConvertTo-NovaCliArgumentArray -BoundParameters $PSBoundParameters -Arguments $Arguments
    $options = @{}

    foreach ($token in $Arguments) {
        switch -Regex ($token) {
            '^(--build|-b)$' {
                $options.Build = $true
            }
            default {
                Stop-NovaOperation -Message "Unknown argument: $token" -ErrorId 'Nova.Validation.UnknownCliArgument' -Category InvalidArgument -TargetObject $token
            }
        }
    }

    return $options
}

