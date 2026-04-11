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
        Write-Error 'Module Name invalid. Module should be one word and contain only Letters,Numbers and '
    }

    return $answer
}


