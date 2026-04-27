function Get-NovaPackageUploadPath {
    [CmdletBinding()]
    param(
        [AllowNull()]$PackageSettings,
        [AllowNull()]$RepositorySettings,
        [string]$UploadPath
    )

    $resolvedUploadPath = Get-NovaFirstConfiguredValue -CandidateList @(
        $UploadPath
        (Get-NovaPackageSettingValue -InputObject $RepositorySettings -Name 'UploadPath')
        (Get-NovaPackageSettingValue -InputObject $PackageSettings -Name 'UploadPath')
    )

    return "$( $resolvedUploadPath )".Trim()
}

