function Add-FunctionSourceIndexEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Index,
        [Parameter(Mandatory)][System.IO.FileInfo]$File,
        [Parameter(Mandatory)][System.Management.Automation.Language.FunctionDefinitionAst]$FunctionAst
    )

    $key = ('' + $FunctionAst.Name).ToLowerInvariant()
    $list = Get-OrCreateHashtableList -Index $Index -Key $key
    $list.Add([pscustomobject]@{
        Path = $File.FullName
        Line = $FunctionAst.Extent.StartLineNumber
    })
}
