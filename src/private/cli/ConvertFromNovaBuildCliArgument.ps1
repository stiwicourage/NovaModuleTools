function ConvertFrom-NovaBuildCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    $Arguments = ConvertTo-NovaCliArgumentArray -BoundParameters $PSBoundParameters -Arguments $Arguments
    $options = @{}

    foreach ($token in $Arguments) {
        switch -Regex ($token) {
            '^(--continuous-integration|-i)$' {
                $options.ContinuousIntegration = $true
            }
            default {
                Stop-NovaOperation -Message "Unknown argument: $token" -ErrorId 'Nova.Validation.UnknownCliArgument' -Category InvalidArgument -TargetObject $token
            }
        }
    }

    return $options
}

