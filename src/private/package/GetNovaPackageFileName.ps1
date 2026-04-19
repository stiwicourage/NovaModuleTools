function Get-NovaPackageFileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$PackageId,
        [Parameter(Mandatory)][string]$PackageType
    )

    $packageType = ConvertTo-NovaPackageType -Type $PackageType
    $packageFileName = "$( $ProjectInfo.Package.PackageFileName )".Trim()
    if ( [string]::IsNullOrWhiteSpace($packageFileName)) {
        $packageFileName = "$PackageId.$( $ProjectInfo.Version )"
    }

    $packageFileName = $packageFileName -replace '(?i)(?:\.nupkg|\.zip)$', ''
    $fileExtension = if ($packageType -eq 'Zip') {
        '.zip'
    }
    else {
        '.nupkg'
    }

    return "$packageFileName$fileExtension"
}

