function ConvertFrom-NovaTestCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    return ConvertFrom-NovaCliSwitchArgument -Arguments $Arguments -TokenMap @{
        '--build' = 'Build'
        '-b' = 'Build'
    }
}
