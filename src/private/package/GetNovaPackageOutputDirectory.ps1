function Get-NovaPackageOutputDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    $outputDirectory = if ($ProjectInfo.Package.OutputDirectory -is [string]) {
        "$( $ProjectInfo.Package.OutputDirectory )".Trim()
    }
    else {
        "$( $ProjectInfo.Package.OutputDirectory.Path )".Trim()
    }

    if ( [System.IO.Path]::IsPathRooted($outputDirectory)) {
        return $outputDirectory
    }

    return [System.IO.Path]::Join($ProjectInfo.ProjectRoot, $outputDirectory)
}
