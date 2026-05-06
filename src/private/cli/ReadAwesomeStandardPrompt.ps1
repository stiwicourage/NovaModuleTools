function Read-AwesomeStandardPrompt {
    param(
        [Parameter(Mandatory)][object]$Ask,
        [Parameter(Mandatory)][object]$HostUi
    )

    $fieldDescription = Get-AwesomePromptFieldDescription -Ask $Ask

    do {
        $response = $HostUi.Prompt(
                (Get-AwesomePromptValue -Ask $Ask -Name 'Caption'),
                (Get-AwesomePromptValue -Ask $Ask -Name 'Message'),
                @($fieldDescription)
        )

        if (Test-AwesomePromptRequiresRetry -Ask $Ask -Response $response) {
            Write-AwesomePromptRetryMessage -Ask $Ask -Response $response
        }
    } while (Test-AwesomePromptRequiresRetry -Ask $Ask -Response $response)

    return Get-AwesomePromptResult -Ask $Ask -Response $response
}
