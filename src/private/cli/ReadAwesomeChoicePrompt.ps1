function Read-AwesomeChoicePrompt {
    param(
        [Parameter(Mandatory)][object]$Ask,
        [Parameter(Mandatory)][object]$HostUi
    )

    $options = Get-AwesomeChoiceOptionList -Choice (Get-AwesomePromptValue -Ask $Ask -Name 'Choice')
    $defaultIndex = $options.Label.IndexOf('&' + (Get-AwesomePromptValue -Ask $Ask -Name 'Default'))
    $response = $HostUi.PromptForChoice(
            (Get-AwesomePromptValue -Ask $Ask -Name 'Caption'),
            (Get-AwesomePromptValue -Ask $Ask -Name 'Message'),
            $options,
            $defaultIndex
    )

    return $options.Label[$response] -replace '&'
}
