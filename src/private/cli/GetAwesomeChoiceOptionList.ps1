function Get-AwesomeChoiceOptionList {
    param([Parameter(Mandatory)][System.Collections.IDictionary]$Choice)

    $choiceList = foreach ($key in $Choice.Keys) {
        New-Object System.Management.Automation.Host.ChoiceDescription "&$key", $Choice[$key]
    }

    return [System.Management.Automation.Host.ChoiceDescription[]]@($choiceList)
}
