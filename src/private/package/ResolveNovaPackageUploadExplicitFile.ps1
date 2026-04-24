function Resolve-NovaPackageUploadExplicitFile {
    [CmdletBinding()]
    param(
        [string[]]$RequestedPackageTypeList,
        [Parameter(Mandatory)][string]$PackagePath
    )

    if (-not (Test-Path -LiteralPath $PackagePath -PathType Leaf)) {
        Stop-NovaOperation -Message "Package file not found: $PackagePath" -ErrorId 'Nova.Environment.PackageUploadFileNotFound' -Category ObjectNotFound -TargetObject $PackagePath
    }

    $resolvedPackagePath = (Resolve-Path -LiteralPath $PackagePath -ErrorAction Stop).Path
    $resolvedPackageType = Get-NovaPackageArtifactType -PackagePath $resolvedPackagePath
    if (@($RequestedPackageTypeList).Count -gt 0 -and $resolvedPackageType -notin $RequestedPackageTypeList) {
        Stop-NovaOperation -Message "Package selection is ambiguous. Explicit PackagePath '$resolvedPackagePath' resolves to type '$resolvedPackageType', but requested PackageType values are: $( $RequestedPackageTypeList -join ', ' )." -ErrorId 'Nova.Validation.PackageUploadSelectionAmbiguous' -Category InvalidArgument -TargetObject $resolvedPackagePath
    }

    return [pscustomobject]@{
        Type = $resolvedPackageType
        PackagePath = $resolvedPackagePath
        PackageFileName = [System.IO.Path]::GetFileName($resolvedPackagePath)
    }
}

