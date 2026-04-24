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
    $targetSettings = Get-NovaPackageUploadTargetSettingBundle -PackageSettings $packageSettings -RepositorySettings $repositorySettings

    return [pscustomobject]@{
        Repository = $targetSettings.Repository
        Url = $resolvedUrl
        UploadPath = $resolvedUploadPath
        Headers = $targetSettings.Headers
        Auth = $targetSettings.Auth
    }
}

