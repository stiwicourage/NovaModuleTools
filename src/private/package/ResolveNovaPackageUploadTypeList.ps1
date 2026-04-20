function Resolve-NovaPackageUploadTypeList {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package upload type list is the domain term represented by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [string[]]$PackageType
    )

    $patternInfo = Get-NovaPackageArtifactPatternInfo -ProjectInfo $ProjectInfo
    $requestedTypeList = @($PackageType | Where-Object {-not [string]::IsNullOrWhiteSpace("$_")})
    if ($requestedTypeList.Count -gt 0) {
        return @(Resolve-NovaRequestedPackageUploadTypeList -RequestedTypeList $requestedTypeList -PatternInfo $patternInfo)
    }

    if ($null -ne $patternInfo.ExplicitPackageType) {
        return @($patternInfo.ExplicitPackageType)
    }

    return @(
    @(Get-NovaPackageMetadataList -ProjectInfo $ProjectInfo).Type |
            Select-Object -Unique
    )
}

function Resolve-NovaRequestedPackageUploadTypeList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$RequestedTypeList,
        [Parameter(Mandatory)][pscustomobject]$PatternInfo
    )

    $resolvedTypeList = @()
    foreach ($requestedType in $RequestedTypeList) {
        $resolvedType = ConvertTo-NovaPackageType -Type $requestedType
        if ($resolvedType -notin $resolvedTypeList) {
            $resolvedTypeList += $resolvedType
        }
    }

    if ($null -eq $PatternInfo.ExplicitPackageType) {
        return $resolvedTypeList
    }

    $matchingRequestedTypeList = @($resolvedTypeList | Where-Object {$_ -eq $PatternInfo.ExplicitPackageType})
    if ($matchingRequestedTypeList.Count -gt 0) {
        return $matchingRequestedTypeList
    }

    throw "Package.FileNamePattern '$( $PatternInfo.Pattern )' resolves to type '$( $PatternInfo.ExplicitPackageType )', but requested PackageType values are: $( $resolvedTypeList -join ', ' )."
}

