function Invoke-NovaCliUpdateCommand {
    [CmdletBinding()]
    param(
        [string[]]$Arguments,
        [Parameter(Mandatory)][hashtable]$ForwardedParameters
    )

    $options = ConvertFrom-NovaUpdateCliArgument -Arguments $Arguments
    return Update-NovaModuleTool @options @ForwardedParameters
}


