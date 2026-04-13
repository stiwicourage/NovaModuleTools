function ConvertFrom-NovaCliArgument {
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
            '^(--local|-Local)$' {
                $options.Local = $true
            }
            '^(--repository|-Repository)$' {
                $index++
                if ($index -ge $Arguments.Count) {
                    throw 'Missing value for --repository'
                }

                $options.Repository = $Arguments[$index]
            }
            '^(--path|-Path|-ModuleDirectoryPath)$' {
                $index++
                if ($index -ge $Arguments.Count) {
                    throw 'Missing value for --path'
                }

                $options.ModuleDirectoryPath = $Arguments[$index]
            }
            '^(--apikey|-ApiKey)$' {
                $index++
                if ($index -ge $Arguments.Count) {
                    throw 'Missing value for --apikey'
                }

                $options.ApiKey = $Arguments[$index]
            }
            default {
                throw "Unknown argument: $token"
            }
        }

        $index++
    }

    return $options
}
