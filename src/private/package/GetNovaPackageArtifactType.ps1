function Get-NovaPackageArtifactType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PackagePath
    )

    $extension = [System.IO.Path]::GetExtension($PackagePath)
    $errorMessage = "Unsupported package file extension for upload: $PackagePath. Supported extensions: .nupkg, .zip."
    if ( [string]::IsNullOrWhiteSpace($extension)) {
        Stop-NovaOperation -Message $errorMessage -ErrorId 'Nova.Validation.UnsupportedPackageUploadFileType' -Category InvalidArgument -TargetObject $PackagePath
    }

    try {
        return ConvertTo-NovaPackageType -Type $extension
    }
    catch {
        Stop-NovaOperation -Message $errorMessage -ErrorId 'Nova.Validation.UnsupportedPackageUploadFileType' -Category InvalidArgument -TargetObject $PackagePath
    }
}
