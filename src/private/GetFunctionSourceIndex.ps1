function Get-IndexableSourceFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$File
    )

    return @($File | Where-Object { $_ -and -not [string]::IsNullOrWhiteSpace($_.FullName) })
}

function Get-IndexableFunctionAstFromFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    return @(Get-TopLevelFunctionAstFromFile -Path $Path | Where-Object { $_ -and -not [string]::IsNullOrWhiteSpace($_.Name) })
}

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

function Get-FunctionSourceIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.IO.FileInfo[]]$File
    )

    $index = @{}

    foreach ($f in (Get-IndexableSourceFile -File $File)) {
        Add-FunctionSourceIndexEntryFromFile -Index $index -File $f
    }

    return $index
}
