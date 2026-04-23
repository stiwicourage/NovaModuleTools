function Get-NovaPackageUploadArtifact {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$PackageFileInfo,
        [Parameter(Mandatory)][pscustomobject]$UploadTarget,
        [Parameter(Mandatory)][object]$UploadHeaders
    )

    return [pscustomobject]@{
        Type = $PackageFileInfo.Type
        PackagePath = $PackageFileInfo.PackagePath
        PackageFileName = $PackageFileInfo.PackageFileName
        Repository = $UploadTarget.Repository
        Headers = $UploadHeaders
        UploadUrl = Join-NovaPackageUploadUrl -Url $UploadTarget.Url -UploadPath $UploadTarget.UploadPath -PackageFileName $PackageFileInfo.PackageFileName
    }
}

