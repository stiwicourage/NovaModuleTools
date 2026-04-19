function Invoke-NovaCliUploadCommand {
    [CmdletBinding()]
    param(
        [string[]]$Arguments,
        [Parameter(Mandatory)][hashtable]$ForwardedParameters
    )

    $options = ConvertFrom-NovaUploadCliArgument -Arguments $Arguments
    return Upload-NovaPackage @options @ForwardedParameters
}

