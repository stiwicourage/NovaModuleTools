function Get-NovaVersionPreReleaseLabel {
    [CmdletBinding()]
    param(
        [AllowNull()][semver]$CurrentVersion,
        [switch]$PreviewRelease,
        [switch]$StableRelease
    )

    if ($PreviewRelease) {
        return Get-NovaPreviewReleaseLabel -CurrentVersion $CurrentVersion
    }

    if ($StableRelease) {
        return $null
    }

    return $null
}

function Get-NovaPreviewReleaseLabel {
    [CmdletBinding()]
    param(
        [AllowNull()][semver]$CurrentVersion
    )

    if ($null -eq $CurrentVersion -or [string]::IsNullOrWhiteSpace($CurrentVersion.PreReleaseLabel)) {
        return 'preview'
    }

    return Get-NovaNextPreReleaseLabel -PreReleaseLabel $CurrentVersion.PreReleaseLabel
}

function Get-NovaNextPreReleaseLabel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PreReleaseLabel
    )

    $match = [regex]::Match($PreReleaseLabel, '^(?<Stem>.*?)(?<Number>\d+)?$')
    $stem = $match.Groups['Stem'].Value
    $preReleaseNumber = $match.Groups['Number'].Value

    if ( [string]::IsNullOrWhiteSpace($preReleaseNumber)) {
        return "$stem`1"
    }

    return "$stem$( [int]$preReleaseNumber + 1 )"
}
