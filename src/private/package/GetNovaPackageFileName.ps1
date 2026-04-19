function Get-NovaPackageFileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$PackageId,
        [Parameter(Mandatory)][string]$PackageType,
        [switch]$Latest
    )

    $packageType = ConvertTo-NovaPackageType -Type $PackageType
    $packageFileName = "$( $ProjectInfo.Package.PackageFileName )".Trim()
    if ( [string]::IsNullOrWhiteSpace($packageFileName)) {
        $packageFileName = "$PackageId.$( $ProjectInfo.Version )"
    }

    $packageFileName = $packageFileName -replace '(?i)(?:\.nupkg|\.zip)$', ''
    if ($Latest) {
        $versionSuffix = ".$( $ProjectInfo.Version )"
        if ( $packageFileName.EndsWith($versionSuffix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $packageFileName = "$($packageFileName.Substring(0, $packageFileName.Length - $versionSuffix.Length) ).latest"
        }
        elseif (-not $packageFileName.EndsWith('.latest', [System.StringComparison]::OrdinalIgnoreCase)) {
            $packageFileName = "$packageFileName.latest"
        }
    }

    $fileExtension = if ($packageType -eq 'Zip') {
        '.zip'
    }
    else {
        '.nupkg'
    }

    return "$packageFileName$fileExtension"
}

