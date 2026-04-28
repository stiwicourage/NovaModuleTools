function ConvertFrom-NovaBumpCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    return ConvertFrom-NovaCliSwitchArgument -Arguments $Arguments -TokenMap @{
        '--preview' = 'Preview'
        '-p' = 'Preview'
        '--continuous-integration' = 'ContinuousIntegration'
        '-i' = 'ContinuousIntegration'
    }
}
