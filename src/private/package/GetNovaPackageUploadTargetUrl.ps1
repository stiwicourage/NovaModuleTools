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
        $resolvedUrl = Get-NovaPackageSettingValue -InputObject $PackageSettings -Name 'RepositoryUrl'
    }
    if ( [string]::IsNullOrWhiteSpace("$resolvedUrl")) {
        $resolvedUrl = Get-NovaPackageSettingValue -InputObject $PackageSettings -Name 'RawRepositoryUrl'
    }
    if ( [string]::IsNullOrWhiteSpace("$resolvedUrl")) {
        Stop-NovaOperation -Message 'Upload target URL is missing. Provide -Url or configure Package.RepositoryUrl or Package.Repositories[].Url.' -ErrorId 'Nova.Configuration.PackageUploadTargetUrlMissing' -Category InvalidData -TargetObject 'Url'
    }

    return "$resolvedUrl".Trim()
}

