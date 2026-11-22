function Get-NovaPackageTypeExtension {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$PackageType
    )

    $resolvedPackageType = ConvertTo-NovaPackageType -Type $PackageType
    if ($resolvedPackageType -eq 'Zip') {
        return '.zip'
    }

    return '.nupkg'
}
