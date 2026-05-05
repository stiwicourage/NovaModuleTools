function Get-AwesomePromptValidationFailure {
    param(
        [Parameter(Mandatory)][object]$Ask,
        [AllowNull()]$Value
    )

    $validation = Get-AwesomePromptValue -Ask $Ask -Name 'Validation'
    if ($null -eq $validation) {
        return $null
    }

    $validator = Get-AwesomePromptValue -Ask $validation -Name 'Test'
    if ($null -eq $validator) {
        return $null
    }

    if ([bool](& $validator $Value)) {
        return $null
    }

    return [pscustomobject]@{
        Message = Get-AwesomePromptValue -Ask $validation -Name 'Message'
        ErrorId = Get-AwesomePromptValue -Ask $validation -Name 'ErrorId'
        Category = Get-AwesomePromptValue -Ask $validation -Name 'Category'
        TargetObject = $Value
    }
}

