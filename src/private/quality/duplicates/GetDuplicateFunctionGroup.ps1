function Get-DuplicateFunctionGroup {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)][System.Management.Automation.Language.FunctionDefinitionAst[]]$FunctionAst
    )

    return @(
    $FunctionAst |
            Group-Object -Property {('' + $_.Name).ToLowerInvariant()} |
            Where-Object {$_.Count -gt 1}
    )
}
