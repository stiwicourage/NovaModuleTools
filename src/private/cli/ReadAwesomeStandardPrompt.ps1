function Read-AwesomeStandardPrompt {
    param(
        [Parameter(Mandatory)][pscustomobject]$Ask,
        [Parameter(Mandatory)][object]$HostUi
    )

    do {
        $response = $HostUi.Prompt($Ask.Caption, $Ask.Message, $Ask.Prompt)
    } while (Test-AwesomePromptRequiresRetry -Ask $Ask -Response $response)

    return Get-AwesomePromptResult -Ask $Ask -Response $response
}

