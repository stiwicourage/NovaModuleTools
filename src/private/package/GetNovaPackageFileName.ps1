function Get-NovaPackageFileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$PackageId,
        [Parameter(Mandatory)][string]$PackageType,
        [switch]$Latest
    )

    $packageType = ConvertTo-NovaPackageType -Type $PackageType
    $packageFileName = Get-NovaPackageBaseFileName -ProjectInfo $ProjectInfo -PackageId $PackageId
    if ($Latest) {
        $packageFileName = ConvertTo-NovaLatestPackageFileName -PackageFileName $packageFileName -Version $ProjectInfo.Version
    }

    return "$packageFileName$( Get-NovaPackageTypeExtension -PackageType $packageType )"
}

function Get-NovaPackageBaseFileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$PackageId
    )

    $packageFileName = "$( $ProjectInfo.Package.PackageFileName )".Trim()
    if ( [string]::IsNullOrWhiteSpace($packageFileName)) {
        return "$PackageId.$( $ProjectInfo.Version )"
    }

    $packageFileName = $packageFileName -replace '(?i)(?:\.nupkg|\.zip)$', ''
    if (-not (Get-NovaPackageSettingValue -InputObject $ProjectInfo.Package -Name 'AddVersionToFileName')) {
        return $packageFileName
    }

    return Add-NovaPackageVersionSuffix -PackageFileName $packageFileName -Version $ProjectInfo.Version
}

function Add-NovaPackageVersionSuffix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PackageFileName,
        [Parameter(Mandatory)][string]$Version
    )

    $versionSuffix = ".${Version}"
    if ( $PackageFileName.EndsWith($versionSuffix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $PackageFileName
    }

    return "$PackageFileName$versionSuffix"
}

function ConvertTo-NovaLatestPackageFileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PackageFileName,
        [Parameter(Mandatory)][string]$Version
    )

    $versionSuffix = ".${Version}"
    if ( $PackageFileName.EndsWith($versionSuffix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return "$($PackageFileName.Substring(0, $PackageFileName.Length - $versionSuffix.Length) ).latest"
    }

    if (-not $PackageFileName.EndsWith('.latest', [System.StringComparison]::OrdinalIgnoreCase)) {
        return "$PackageFileName.latest"
    }

    return $PackageFileName
}
