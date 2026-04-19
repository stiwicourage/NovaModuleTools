function Get-NovaPackageArtifactSearchPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$PackageType
    )

    $pattern = "$( Get-NovaPackageSettingValue -InputObject $ProjectInfo.Package -Name 'FileNamePattern' )".Trim()
    if ( [string]::IsNullOrWhiteSpace($pattern)) {
        $packageId = "$( Get-NovaPackageSettingValue -InputObject $ProjectInfo.Package -Name 'Id' )".Trim()
        $pattern = "$packageId*"
    }

    $pattern = $pattern -replace '(?i)(?:\.nupkg|\.zip)$', ''
    return "$pattern$( Get-NovaPackageTypeExtension -PackageType $PackageType )"
}

