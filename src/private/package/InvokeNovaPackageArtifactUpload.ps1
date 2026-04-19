function Invoke-NovaPackageArtifactUpload {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Upload-NovaPackage performs the user-facing ShouldProcess confirmation before calling this internal helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$UploadArtifact
    )

    if (-not (Test-Path -LiteralPath $UploadArtifact.PackagePath -PathType Leaf)) {
        throw "Package file not found: $( $UploadArtifact.PackagePath )"
    }

    $webRequestParameters = @{
        Uri = $UploadArtifact.UploadUrl
        Method = 'Put'
        InFile = $UploadArtifact.PackagePath
    }
    if (@($UploadArtifact.Headers.Keys).Count -gt 0) {
        $webRequestParameters.Headers = $UploadArtifact.Headers
    }

    $webRequestCommand = Get-Command -Name Invoke-WebRequest -CommandType Cmdlet -ErrorAction Stop
    if ( $webRequestCommand.Parameters.ContainsKey('UseBasicParsing')) {
        $webRequestParameters.UseBasicParsing = $true
    }

    try {
        $response = Invoke-WebRequest @webRequestParameters
    }
    catch {
        throw "Package upload failed for $( $UploadArtifact.PackagePath ) -> $( $UploadArtifact.UploadUrl ). $( $_.Exception.Message )"
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

