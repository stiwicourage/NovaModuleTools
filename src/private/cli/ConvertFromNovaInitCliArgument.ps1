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
            '^(--path|-Path)$' {
                $index++
                if ($index -ge $Arguments.Count) {
                    throw 'Missing value for --path'
                }

                $options.Path = $Arguments[$index]
            }
            '^(--example|-Example)$' {
                $options.Example = $true
            }
            default {
                if ( $token.StartsWith('-')) {
                    throw "Unknown argument: $token"
                }

                throw "Unsupported 'nova init' usage: positional paths are no longer accepted. Use 'nova init -Path $token' instead."
            }
        }

        $index++
    }

    return $options
}

