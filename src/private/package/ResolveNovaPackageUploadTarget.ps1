function Resolve-NovaPackageUploadTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [string]$Url,
        [string]$Repository,
        [string]$UploadPath
    )

    $packageSettings = $ProjectInfo.Package
    $repositorySettings = Get-NovaPackageRepository -ProjectInfo $ProjectInfo -Repository $Repository
    $resolvedUrl = Get-NovaPackageUploadTargetUrl -PackageSettings $packageSettings -RepositorySettings $repositorySettings -Url $Url
    $resolvedUploadPath = Get-NovaPackageUploadPath -PackageSettings $packageSettings -RepositorySettings $repositorySettings -UploadPath $UploadPath

    return [pscustomobject]@{
        Repository = "$( Get-NovaPackageSettingValue -InputObject $repositorySettings -Name 'Name' )".Trim()
        Url = $resolvedUrl
        UploadPath = $resolvedUploadPath
        Headers = Merge-NovaPackageSettingTable -BaseSettings (Get-NovaPackageSettingValue -InputObject $packageSettings -Name 'Headers') -OverrideSettings (Get-NovaPackageSettingValue -InputObject $repositorySettings -Name 'Headers')
        Auth = Merge-NovaPackageSettingTable -BaseSettings (Get-NovaPackageSettingValue -InputObject $packageSettings -Name 'Auth') -OverrideSettings (Get-NovaPackageSettingValue -InputObject $repositorySettings -Name 'Auth')
    }
}

