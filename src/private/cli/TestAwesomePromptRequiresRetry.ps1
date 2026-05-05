function Test-AwesomePromptRequiresRetry {
    param(
        [Parameter(Mandatory)][object]$Ask,
        [Parameter(Mandatory)][object]$Response
    )

    if ((Get-AwesomePromptValue -Ask $Ask -Name 'Default') -eq 'MANDATORY' -and [string]::IsNullOrEmpty($Response.Values)) {
        return $true
    }

    $value = Get-AwesomePromptResult -Ask $Ask -Response $Response
    return $null -ne (Get-AwesomePromptValidationFailure -Ask $Ask -Value $value)
}
