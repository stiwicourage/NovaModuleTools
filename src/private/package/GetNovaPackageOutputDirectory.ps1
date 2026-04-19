function Get-NovaPackageOutputDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    $outputDirectory = "$( $ProjectInfo.Package.OutputDirectory )".Trim()
    if ( [System.IO.Path]::IsPathRooted($outputDirectory)) {
        return $outputDirectory
    }

    return [System.IO.Path]::Join($ProjectInfo.ProjectRoot, $outputDirectory)
}

