function Read-AwesomeChoicePrompt {
    param(
        [Parameter(Mandatory)][pscustomobject]$Ask,
        [Parameter(Mandatory)][object]$HostUi
    )

    $options = Get-AwesomeChoiceOptionList -Choice $Ask.Choice
    $defaultIndex = $options.Label.IndexOf('&' + $Ask.Default)
    $response = $HostUi.PromptForChoice($Ask.Caption, $Ask.Message, $options, $defaultIndex)

    return $options.Label[$response] -replace '&'
}
