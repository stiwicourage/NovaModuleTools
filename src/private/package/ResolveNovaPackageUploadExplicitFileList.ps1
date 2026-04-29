function Resolve-NovaPackageUploadExplicitFileList {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package upload explicit file list is the domain term represented by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string[]]$PackagePath,
        [string[]]$PackageType
    )

    $requestedTypeList = @(Get-NovaPackageUploadRequestedTypeList -ProjectInfo $ProjectInfo -PackageType $PackageType)

    $resolvedFileList = @(
    $PackagePath |
            ForEach-Object {Resolve-NovaPackageUploadExplicitFile -RequestedPackageTypeList $requestedTypeList -PackagePath $_} |
            Sort-Object PackagePath -Unique
    )

    return $resolvedFileList
}
