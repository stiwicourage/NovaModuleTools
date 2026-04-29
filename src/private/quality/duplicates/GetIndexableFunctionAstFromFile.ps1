function Get-IndexableFunctionAstFromFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    return @(Get-TopLevelFunctionAstFromFile -Path $Path | Where-Object {$_ -and -not [string]::IsNullOrWhiteSpace($_.Name)})
}
