function Get-AwesomePromptResult {
    param(
        [Parameter(Mandatory)][object]$Ask,
        [Parameter(Mandatory)][object]$Response
    )

    if ( [string]::IsNullOrEmpty($Response.Values)) {
        return Get-AwesomePromptValue -Ask $Ask -Name 'Default'
    }

    return $Response.Values
}
