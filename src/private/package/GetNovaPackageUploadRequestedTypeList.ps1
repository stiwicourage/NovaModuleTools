function Get-NovaPackageUploadRequestedTypeList {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package upload requested type list is the domain term represented by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [string[]]$PackageType
    )

    $requestedTypeList = @($PackageType | Where-Object {-not [string]::IsNullOrWhiteSpace("$_")})
    if ($requestedTypeList.Count -eq 0) {
        return @()
    }

    return @(Resolve-NovaPackageUploadTypeList -ProjectInfo $ProjectInfo -PackageType $requestedTypeList)
}
