function Resolve-NovaPackageUploadTypeList {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package upload type list is the domain term represented by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [string[]]$PackageType
    )

    $requestedTypeList = @($PackageType | Where-Object {-not [string]::IsNullOrWhiteSpace("$_")})
    if ($requestedTypeList.Count -gt 0) {
        $resolvedTypeList = @()
        foreach ($requestedType in $requestedTypeList) {
            $resolvedType = ConvertTo-NovaPackageType -Type $requestedType
            if ($resolvedType -notin $resolvedTypeList) {
                $resolvedTypeList += $resolvedType
            }
        }

        return $resolvedTypeList
    }

    return @(
    @(Get-NovaPackageMetadataList -ProjectInfo $ProjectInfo).Type |
            Select-Object -Unique
    )
}

