function Get-NovaPesterTestResultPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    return [System.IO.Path]::Join($ProjectRoot, 'artifacts', 'TestResults.xml')
}

