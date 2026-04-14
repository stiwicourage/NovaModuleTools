function Read-AwesomeStandardPrompt {
    param(
        [Parameter(Mandatory)][pscustomobject]$Ask,
        [Parameter(Mandatory)][object]$HostUi
    )

    $fieldDescription = [System.Management.Automation.Host.FieldDescription]::new($Ask.Prompt)
    if ($Ask.Default -ne 'MANDATORY') {
        $fieldDescription.DefaultValue = $Ask.Default
    }

    do {
        $response = $HostUi.Prompt($Ask.Caption, $Ask.Message, @($fieldDescription))
    } while (Test-AwesomePromptRequiresRetry -Ask $Ask -Response $response)

    return Get-AwesomePromptResult -Ask $Ask -Response $response
}

