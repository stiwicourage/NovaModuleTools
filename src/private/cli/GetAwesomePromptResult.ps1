function Get-AwesomePromptResult {
    param(
        [Parameter(Mandatory)][pscustomobject]$Ask,
        [Parameter(Mandatory)][object]$Response
    )

    if ( [string]::IsNullOrEmpty($Response.Values)) {
        return $Ask.Default
    }

    return $Response.Values
}
