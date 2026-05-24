function ConvertFrom-NovaCopilotCliArgument {
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
            '^(--short-name|-n)$' {
                $options.ShortName = Get-NovaCliRequiredArgumentValue -Arguments $Arguments -Index ([ref]$index) -OptionName '--short-name'
            }
            '^(--override-warning|-o)$' {
                $options.OverrideWarning = $true
            }
            '^(--what-if|-w)$' {
                $options.WhatIf = $true
            }
            '^(--verbose|-v)$' {
                $options.Verbose = $true
            }
            default {
                Stop-NovaOperation -Message "Unknown argument: $token" -ErrorId 'Nova.Validation.UnknownCliArgument' -Category InvalidArgument -TargetObject $token
            }
        }

        $index++
    }

    return $options
}
