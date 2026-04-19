function Resolve-NovaPackageUploadInvocation {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package upload invocation is the domain term represented by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][pscustomobject]$UploadOption
    )

    $uploadFileList = @(Get-NovaPackageUploadFileList -ProjectInfo $ProjectInfo -PackagePath $UploadOption.PackagePath -PackageType $UploadOption.PackageType)
    $uploadTarget = Resolve-NovaPackageUploadTarget -ProjectInfo $ProjectInfo -Url $UploadOption.Url -Repository $UploadOption.Repository -UploadPath $UploadOption.UploadPath
    $uploadHeaders = Resolve-NovaPackageUploadHeaders -UploadTarget $uploadTarget -UploadOption $UploadOption

    return @(
    $uploadFileList | ForEach-Object {
        [pscustomobject]@{
            Type = $_.Type
            PackagePath = $_.PackagePath
            PackageFileName = $_.PackageFileName
            Repository = $uploadTarget.Repository
            Headers = $uploadHeaders
            UploadUrl = Join-NovaPackageUploadUrl -Url $uploadTarget.Url -UploadPath $uploadTarget.UploadPath -PackageFileName $_.PackageFileName
        }
    }
    )
}
