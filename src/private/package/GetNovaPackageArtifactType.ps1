function Get-NovaPackageArtifactType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PackagePath
    )

    $extension = [System.IO.Path]::GetExtension($PackagePath)
    if ( [string]::IsNullOrWhiteSpace($extension)) {
        throw "Unsupported package file extension for upload: $PackagePath. Supported extensions: .nupkg, .zip."
    }

    try {
        return ConvertTo-NovaPackageType -Type $extension
    }
    catch {
        throw "Unsupported package file extension for upload: $PackagePath. Supported extensions: .nupkg, .zip."
    }
}

