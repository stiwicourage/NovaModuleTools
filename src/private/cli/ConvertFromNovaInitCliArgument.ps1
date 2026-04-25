function ConvertFrom-NovaInitCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    $Arguments = ConvertTo-NovaCliArgumentArray -BoundParameters $PSBoundParameters -Arguments $Arguments
    $options = @{}
    $index = 0

    while ($index -lt $Arguments.Count) {
        $token = $Arguments[$index]

        switch -Regex ($token) {
            '^(--path|-p)$' {
                $options.Path = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--path'
            }
            '^(--example|-e)$' {
                $options.Example = $true
            }
            default {
                if ( $token.StartsWith('-')) {
                    Stop-NovaOperation -Message "Unknown argument: $token" -ErrorId 'Nova.Validation.UnknownCliArgument' -Category InvalidArgument -TargetObject $token
                }

                Stop-NovaOperation -Message "Unsupported 'nova init' usage: positional paths are no longer accepted. Use 'nova init --path $token' or 'nova init -p $token' instead." -ErrorId 'Nova.Validation.UnsupportedInitCliUsage' -Category InvalidArgument -TargetObject $token
            }
        }

        $index++
    }

    return $options
}
