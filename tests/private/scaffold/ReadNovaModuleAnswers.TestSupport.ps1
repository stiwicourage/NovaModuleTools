function Get-AwesomePromptValue {
    param($Ask, [string]$Name)
    if ($null -eq $Ask) {return $null}
    if ($Ask -is [System.Collections.IDictionary]) {
        if ($Ask.Contains($Name)) {return $Ask[$Name]}
        return $null
    }
    if ($Ask.PSObject.Properties[$Name]) {return $Ask.$Name}
    return $null
}
function Read-AwesomeHost {param($Ask)}
function Assert-NovaModuleQuestionAnswerValid {param($Question, $Value)}
