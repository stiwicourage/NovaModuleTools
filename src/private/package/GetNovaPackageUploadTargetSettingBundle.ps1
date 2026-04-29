function Get-NovaPackageUploadTargetSettingBundle {
    [CmdletBinding()]
    param(
        [AllowNull()]$PackageSettings,
        [AllowNull()]$RepositorySettings
    )

    return [pscustomobject]@{
        Repository = "$( Get-NovaPackageSettingValue -InputObject $RepositorySettings -Name 'Name' )".Trim()
        Headers = Merge-NovaPackageSettingTable -BaseSettings (Get-NovaPackageSettingValue -InputObject $PackageSettings -Name 'Headers') -OverrideSettings (Get-NovaPackageSettingValue -InputObject $RepositorySettings -Name 'Headers')
        Auth = Merge-NovaPackageSettingTable -BaseSettings (Get-NovaPackageSettingValue -InputObject $PackageSettings -Name 'Auth') -OverrideSettings (Get-NovaPackageSettingValue -InputObject $RepositorySettings -Name 'Auth')
    }
}
