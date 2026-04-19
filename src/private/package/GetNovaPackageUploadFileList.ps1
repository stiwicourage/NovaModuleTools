function Get-NovaPackageUploadFileList {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package upload file list is the domain term represented by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [string[]]$PackagePath,
        [string[]]$PackageType
    )

    $explicitPackagePathList = @($PackagePath | Where-Object {-not [string]::IsNullOrWhiteSpace("$_")})
    if ($explicitPackagePathList.Count -gt 0) {
        return @(Resolve-NovaPackageUploadExplicitFileList -ProjectInfo $ProjectInfo -PackagePath $explicitPackagePathList -PackageType $PackageType)
    }

    return @(Resolve-NovaPackageUploadOutputFileList -ProjectInfo $ProjectInfo -PackageType $PackageType)
}

