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
