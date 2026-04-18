function Get-NovaPesterRunPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$ProjectInfo
    )

    if ($ProjectInfo.BuildRecursiveFolders) {
        return $ProjectInfo.TestsDir
    }

    return [System.IO.Path]::Join($ProjectInfo.TestsDir, '*.Tests.ps1')
}
