function Test-NovaModuleQuestionShouldBeAsked {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Question,
        [Parameter(Mandatory)][System.Collections.IDictionary]$Answer
    )

    $condition = Get-AwesomePromptValue -Ask $Question -Name 'Condition'
    if ($null -eq $condition) {
        return $true
    }

    return [bool](& $condition $Answer)
}

function Read-NovaModuleAnswerSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Questions
    )

    $answer = [ordered]@{}
    foreach ($question in $Questions.GetEnumerator()) {
        if (-not (Test-NovaModuleQuestionShouldBeAsked -Question $question.Value -Answer $answer)) {
            continue
        }

        $answer[$question.Key] = Read-AwesomeHost -Ask $question.Value
        Assert-NovaModuleQuestionAnswerValid -Question $question.Value -Value $answer[$question.Key]
    }

    return $answer
}
