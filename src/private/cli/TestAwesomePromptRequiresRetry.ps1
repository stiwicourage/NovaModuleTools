function Test-AwesomePromptRequiresRetry {
    param(
        [Parameter(Mandatory)][pscustomobject]$Ask,
        [Parameter(Mandatory)][object]$Response
    )

    return $Ask.Default -eq 'MANDATORY' -and [string]::IsNullOrEmpty($Response.Values)
}

