function Get-TopLevelFunctionAstFromFile {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    $parsed = Get-PowerShellAstFromFile -Path $Path
    if ($parsed.Errors -and $parsed.Errors.Count -gt 0) {
        return @()
    }

    return @(Get-TopLevelFunctionAst -Ast $parsed.Ast)
}
