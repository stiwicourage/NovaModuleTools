function Read-NovaModuleAnswerSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Questions
    )

    $answer = @{}
    foreach ($key in $Questions.Keys) {
        $answer[$key] = Read-AwesomeHost -Ask $Questions[$key]
    }

    if ($answer.ProjectName -notmatch '^[A-Za-z][A-Za-z0-9_.]*$') {
        throw 'Module name is invalid. Use a single word that starts with a letter and contains only letters, numbers, underscores, or periods.'
    }

    return $answer
}


