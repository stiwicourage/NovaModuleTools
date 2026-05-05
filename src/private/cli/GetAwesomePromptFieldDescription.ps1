function Get-AwesomePromptFieldDescription {
    param([Parameter(Mandatory)][object]$Ask)

    $fieldDescription = [System.Management.Automation.Host.FieldDescription]::new(
            (Get-AwesomePromptValue -Ask $Ask -Name 'Prompt')
    )
    $defaultValue = Get-AwesomePromptValue -Ask $Ask -Name 'Default'
    if ($defaultValue -ne 'MANDATORY') {
        $fieldDescription.DefaultValue = $defaultValue
    }

    return $fieldDescription
}


