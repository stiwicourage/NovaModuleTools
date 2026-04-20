function Get-NovaPackageArtifactSearchPattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$PackageType
    )

    $patternInfo = Get-NovaPackageArtifactPatternInfo -ProjectInfo $ProjectInfo
    if ($null -ne $patternInfo.ExplicitPackageType) {
        return $patternInfo.Pattern
    }

    return "$( $patternInfo.Pattern )$( Get-NovaPackageTypeExtension -PackageType $PackageType )"
}

