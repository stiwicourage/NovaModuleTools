function Get-NovaCliRequiredArgumentValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][ref]$Index,
        [Parameter(Mandatory)][string]$OptionName
    )

    $Index.Value++
    if ($Index.Value -ge $Arguments.Count) {
        Stop-NovaOperation -Message "Missing value for $OptionName" -ErrorId 'Nova.Validation.MissingCliOptionValue' -Category InvalidArgument -TargetObject $OptionName
    }

    return $Arguments[$Index.Value]
}
