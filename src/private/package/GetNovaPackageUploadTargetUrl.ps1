function Get-NovaPackageUploadTargetUrl {
    [CmdletBinding()]
    param(
        [AllowNull()]$PackageSettings,
        [AllowNull()]$RepositorySettings,
        [string]$Url
    )

    $resolvedUrl = $Url
    if ( [string]::IsNullOrWhiteSpace($resolvedUrl)) {
        $resolvedUrl = Get-NovaPackageSettingValue -InputObject $RepositorySettings -Name 'Url'
    }
    if ( [string]::IsNullOrWhiteSpace("$resolvedUrl")) {
        $resolvedUrl = Get-NovaPackageSettingValue -InputObject $PackageSettings -Name 'RawRepositoryUrl'
    }
    if ( [string]::IsNullOrWhiteSpace("$resolvedUrl")) {
        throw 'Upload target URL is missing. Provide -Url or configure Package.RawRepositoryUrl or Package.Repositories[].Url.'
    }

    return "$resolvedUrl".Trim()
}

