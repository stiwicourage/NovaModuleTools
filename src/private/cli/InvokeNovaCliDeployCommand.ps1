function Invoke-NovaCliDeployCommand {
    [CmdletBinding()]
    param(
        [string[]]$Arguments,
        [Parameter(Mandatory)][hashtable]$ForwardedParameters
    )

    $options = ConvertFrom-NovaDeployCliArgument -Arguments $Arguments
    return Deploy-NovaPackage @options @ForwardedParameters
}
