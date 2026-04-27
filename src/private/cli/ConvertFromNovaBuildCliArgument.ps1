function ConvertFrom-NovaBuildCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    return ConvertFrom-NovaCliSwitchArgument -Arguments $Arguments -TokenMap @{
        '--continuous-integration' = 'ContinuousIntegration'
        '-i' = 'ContinuousIntegration'
    }
}

