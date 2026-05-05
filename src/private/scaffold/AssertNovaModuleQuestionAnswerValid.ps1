function Assert-NovaModuleQuestionAnswerValid {
    param(
        [Parameter(Mandatory)][object]$Question,
        [AllowNull()]$Value
    )

    $validationFailure = Get-AwesomePromptValidationFailure -Ask $Question -Value $Value
    if ($null -eq $validationFailure) {
        return
    }

    Stop-NovaOperation -Message $validationFailure.Message -ErrorId $validationFailure.ErrorId -Category $validationFailure.Category -TargetObject $validationFailure.TargetObject
}

