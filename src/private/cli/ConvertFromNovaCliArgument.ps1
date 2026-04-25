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
            '^(--local|-l)$' {
                $options.Local = $true
            }
            '^(--repository|-r)$' {
                $options.Repository = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--repository'
            }
            '^(--path|-p)$' {
                $options.ModuleDirectoryPath = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--path'
            }
            '^(--api-key|-k)$' {
                $options.ApiKey = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--api-key'
            }
            default {
                Stop-NovaOperation -Message "Unknown argument: $token" -ErrorId 'Nova.Validation.UnknownCliArgument' -Category InvalidArgument -TargetObject $token
            }
        }

        $index++
    }

    return $options
}
