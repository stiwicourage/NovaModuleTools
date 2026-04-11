function Add-FunctionSourceIndexEntryFromFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Index,
        [Parameter(Mandatory)][System.IO.FileInfo]$File
    )

    foreach ($fn in (Get-IndexableFunctionAstFromFile -Path $File.FullName)) {
        Add-FunctionSourceIndexEntry -Index $Index -File $File -FunctionAst $fn
    }
}
