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
    $versionPart = Get-NovaVersionPartForUpdatePlan -CurrentVersion $currentVersion -Label $Label -PreviewRelease:$PreviewRelease
    $releaseType = Get-NovaVersionPreReleaseLabel -CurrentVersion $currentVersion -PreviewRelease:$PreviewRelease -StableRelease:$StableRelease
    $newVersion = [semver]::new($versionPart.Major, $versionPart.Minor, $versionPart.Patch, $releaseType, $null)

    return [pscustomobject]@{
        ProjectFile = $projectInfo.ProjectJSON
        CurrentVersion = $currentVersion
        NewVersion = $newVersion
    }
}

function Get-NovaVersionPartForUpdatePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][semver]$CurrentVersion,
        [Parameter(Mandatory)][string]$Label,
        [switch]$PreviewRelease
    )

    if ($PreviewRelease -and -not [string]::IsNullOrWhiteSpace($CurrentVersion.PreReleaseLabel)) {
        return Get-NovaVersionPartObject -CurrentVersion $CurrentVersion
    }

    return Get-NovaVersionPartForLabel -CurrentVersion $CurrentVersion -Label $Label
}
