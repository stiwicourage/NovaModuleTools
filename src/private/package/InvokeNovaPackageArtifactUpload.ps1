function Invoke-NovaPackageArtifactUpload {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Deploy-NovaPackage performs the user-facing ShouldProcess confirmation before calling this internal helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$UploadArtifact
    )

    if (-not (Test-Path -LiteralPath $UploadArtifact.PackagePath -PathType Leaf)) {
        Stop-NovaOperation -Message "Package file not found: $( $UploadArtifact.PackagePath )" -ErrorId 'Nova.Environment.PackageUploadFileNotFound' -Category ObjectNotFound -TargetObject $UploadArtifact.PackagePath
    }

    try {
        $response = Invoke-NovaPackageUploadRequest -UploadArtifact $UploadArtifact
    }
    catch {
        Stop-NovaOperation -Message "Package upload failed for $( $UploadArtifact.PackagePath ) -> $( $UploadArtifact.UploadUrl ). $( $_.Exception.Message )" -ErrorId 'Nova.Dependency.PackageUploadRequestFailed' -Category ConnectionError -TargetObject $UploadArtifact.UploadUrl
    }

    return [pscustomobject]@{
        Type = $UploadArtifact.Type
        PackagePath = $UploadArtifact.PackagePath
        PackageFileName = $UploadArtifact.PackageFileName
        Repository = $UploadArtifact.Repository
        UploadUrl = $UploadArtifact.UploadUrl
        StatusCode = Get-NovaPackageUploadStatusCode -Response $response
    }
}
