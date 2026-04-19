function Get-NovaPackageFileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$PackageId
    )

    $packageFileName = "$( $ProjectInfo.Package.PackageFileName )".Trim()
    if ( [string]::IsNullOrWhiteSpace($packageFileName)) {
        $packageFileName = "$PackageId.$( $ProjectInfo.Version ).nupkg"
    }

    if (-not $packageFileName.EndsWith('.nupkg', [System.StringComparison]::OrdinalIgnoreCase)) {
        $packageFileName = "$packageFileName.nupkg"
    }

    return $packageFileName
}

