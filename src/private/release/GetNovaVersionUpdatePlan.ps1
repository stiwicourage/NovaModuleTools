function Get-NovaVersionUpdatePlan {
    [CmdletBinding()]
    param(
        [ValidateSet('Major', 'Minor', 'Patch')]
        [string]$Label = 'Patch',
        [switch]$PreviewRelease,
        [switch]$StableRelease,
        [pscustomobject]$ProjectInfo
    )

    $projectInfo = Get-NovaVersionUpdateProjectInfo -ProjectInfo $ProjectInfo
    $currentVersion = Get-NovaCurrentVersionForUpdatePlan -ProjectInfo $projectInfo
    $versionPart = Get-NovaVersionPartForUpdatePlan -CurrentVersion $currentVersion -Label $Label -PreviewRelease:$PreviewRelease
    $releaseType = Get-NovaVersionPreReleaseLabel -CurrentVersion $currentVersion -PreviewRelease:$PreviewRelease -StableRelease:$StableRelease
    $newVersion = [semver]::new($versionPart.Major, $versionPart.Minor, $versionPart.Patch, $releaseType, $null)

    return [pscustomobject]@{
        ProjectFile = $projectInfo.ProjectJSON
        CurrentVersion = $currentVersion
        NewVersion = $newVersion
    }
}

function Get-NovaVersionUpdateProjectInfo {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo
    )

    if ($null -ne $ProjectInfo) {
        return $ProjectInfo
    }

    return Get-NovaProjectInfo
}

function Get-NovaCurrentVersionForUpdatePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    $hasVersion = $ProjectInfo.PSObject.Properties.Name -contains 'Version'
    if ($hasVersion -and -not [string]::IsNullOrWhiteSpace($ProjectInfo.Version)) {
        return [semver]$ProjectInfo.Version
    }

    $projectJsonData = Read-ProjectJsonData -ProjectJsonPath $ProjectInfo.ProjectJSON
    return [semver]$projectJsonData.Version
}

function Get-NovaVersionPartForUpdatePlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][semver]$CurrentVersion,
        [Parameter(Mandatory)][string]$Label,
        [switch]$PreviewRelease
    )

    if (Test-NovaVersionShouldPreserveInitialStableReleaseTarget -CurrentVersion $CurrentVersion -PreviewRelease:$PreviewRelease) {
        return Get-NovaVersionPartObject -CurrentVersion $CurrentVersion
    }

    if ($PreviewRelease) {
        if (-not [string]::IsNullOrWhiteSpace($CurrentVersion.PreReleaseLabel)) {
            return Get-NovaVersionPartObject -CurrentVersion $CurrentVersion
        }

        return Get-NovaVersionPartForLabel -CurrentVersion $CurrentVersion -Label Patch
    }

    return Get-NovaVersionPartForLabel -CurrentVersion $CurrentVersion -Label $Label
}

function Test-NovaVersionShouldPreserveInitialStableReleaseTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][semver]$CurrentVersion,
        [switch]$PreviewRelease
    )

    if ($PreviewRelease) {
        return $false
    }

    if (-not [string]::IsNullOrWhiteSpace($CurrentVersion.PreReleaseLabel)) {
        return $false
    }

    return $CurrentVersion.Major -eq 1 -and $CurrentVersion.Minor -eq 0 -and $CurrentVersion.Patch -eq 0
}
