function Write-AwesomePromptRetryMessage {
    param(
        [Parameter(Mandatory)][object]$Ask,
        [Parameter(Mandatory)][object]$Response
    )

    $value = Get-AwesomePromptResult -Ask $Ask -Response $Response
    $failure = Get-AwesomePromptValidationFailure -Ask $Ask -Value $value
    if ($null -eq $failure) {
        return
    }

    Write-Message -Text $failure.Message -color Yello
}

