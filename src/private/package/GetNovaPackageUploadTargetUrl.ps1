function Get-NovaPackageUploadTargetUrl {
    [CmdletBinding()]
    param(
        [AllowNull()]$PackageSettings,
        [AllowNull()]$RepositorySettings,
        [string]$Url
    )

    $resolvedUrl = Get-NovaFirstConfiguredValue -CandidateList @(
        $Url
        (Get-NovaPackageSettingValue -InputObject $RepositorySettings -Name 'Url')
        (Get-NovaPackageSettingValue -InputObject $PackageSettings -Name 'RepositoryUrl')
        (Get-NovaPackageSettingValue -InputObject $PackageSettings -Name 'RawRepositoryUrl')
    )
    if (-not (Test-NovaConfiguredValue -Value $resolvedUrl)) {
        Stop-NovaOperation -Message 'Upload target URL is missing. Provide -Url or configure Package.RepositoryUrl or Package.Repositories[].Url.' -ErrorId 'Nova.Configuration.PackageUploadTargetUrlMissing' -Category InvalidData -TargetObject 'Url'
    }

    return "$resolvedUrl".Trim()
}
