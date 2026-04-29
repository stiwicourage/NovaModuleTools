function Get-NovaPackageUploadFileInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PackageType,
        [Parameter(Mandatory)][string]$PackagePath,
        [string]$PackageFileName
    )

    $resolvedPackageFileName = $PackageFileName
    if ( [string]::IsNullOrWhiteSpace($resolvedPackageFileName)) {
        $resolvedPackageFileName = [System.IO.Path]::GetFileName($PackagePath)
    }

    return [pscustomobject]@{
        Type = $PackageType
        PackagePath = $PackagePath
        PackageFileName = $resolvedPackageFileName
    }
}
