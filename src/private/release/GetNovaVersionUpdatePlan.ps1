function Get-NovaVersionUpdatePlan {
    [CmdletBinding()]
    param(
        [ValidateSet('Major', 'Minor', 'Patch')]
        [string]$Label = 'Patch',
        [switch]$PreviewRelease,
        [switch]$StableRelease
    )

    $projectInfo = Get-NovaProjectInfo
    $jsonContent = Get-Content -LiteralPath $projectInfo.ProjectJSON -Raw | ConvertFrom-Json
    [semver]$currentVersion = $jsonContent.Version
    $versionPart = Get-NovaVersionPartForLabel -CurrentVersion $currentVersion -Label $Label
    $releaseType = Get-NovaVersionPreReleaseLabel -CurrentVersion $currentVersion -PreviewRelease:$PreviewRelease -StableRelease:$StableRelease
    $newVersion = [semver]::new($versionPart.Major, $versionPart.Minor, $versionPart.Patch, $releaseType, $null)

    return [pscustomobject]@{
        ProjectFile = $projectInfo.ProjectJSON
        CurrentVersion = $currentVersion
        NewVersion = $newVersion
    }
}

