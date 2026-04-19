function Get-NovaPackageUploadPath {
    [CmdletBinding()]
    param(
        [AllowNull()]$PackageSettings,
        [AllowNull()]$RepositorySettings,
        [string]$UploadPath
    )

    if (-not [string]::IsNullOrWhiteSpace($UploadPath)) {
        return $UploadPath.Trim()
    }

    $repositoryUploadPath = Get-NovaPackageSettingValue -InputObject $RepositorySettings -Name 'UploadPath'
    if (-not [string]::IsNullOrWhiteSpace("$repositoryUploadPath")) {
        return "$repositoryUploadPath".Trim()
    }

    $packageUploadPath = Get-NovaPackageSettingValue -InputObject $PackageSettings -Name 'UploadPath'
    return "$( $packageUploadPath )".Trim()
}

