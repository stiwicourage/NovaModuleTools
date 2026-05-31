function Get-NovaPesterTestResultPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter()][string]$FileName = 'TestResults.xml'
    )

    return [System.IO.Path]::Join($ProjectRoot, 'artifacts', $FileName)
}
