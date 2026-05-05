function Read-NovaModuleAnswerSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Questions
    )

    $answer = [ordered]@{}
    foreach ($question in $Questions.GetEnumerator()) {
        $answer[$question.Key] = Read-AwesomeHost -Ask $question.Value
        Assert-NovaModuleQuestionAnswerValid -Question $question.Value -Value $answer[$question.Key]
    }

    return $answer
}
