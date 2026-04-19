function Get-NovaCliRequiredArgumentValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][ref]$Index,
        [Parameter(Mandatory)][string]$OptionName
    )

    $Index.Value++
    if ($Index.Value -ge $Arguments.Count) {
        throw "Missing value for $OptionName"
    }

    return $Arguments[$Index.Value]
}

