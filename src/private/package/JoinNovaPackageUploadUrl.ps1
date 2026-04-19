function Join-NovaPackageUploadUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Url,
        [string]$UploadPath,
        [Parameter(Mandatory)][string]$PackageFileName
    )

    $urlPartList = @($Url.TrimEnd('/'))
    if (-not [string]::IsNullOrWhiteSpace($UploadPath)) {
        $urlPartList += $UploadPath.Trim('/').Trim()
    }

    $urlPartList += [System.Uri]::EscapeDataString($PackageFileName)
    return $urlPartList -join '/'
}

