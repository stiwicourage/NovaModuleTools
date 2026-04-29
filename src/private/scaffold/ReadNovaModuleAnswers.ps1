function Read-NovaModuleAnswerSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary]$Questions
    )

    $answer = [ordered]@{}
    foreach ($question in $Questions.GetEnumerator()) {
        $answer[$question.Key] = Read-AwesomeHost -Ask $question.Value
    }

    if ($answer.ProjectName -notmatch '^[A-Za-z][A-Za-z0-9_.]*$') {
        Stop-NovaOperation -Message 'Module name is invalid. Use a single word that starts with a letter and contains only letters, numbers, underscores, or periods.' -ErrorId 'Nova.Validation.ScaffoldProjectNameInvalid' -Category InvalidData -TargetObject $answer.ProjectName
    }

    return $answer
}
