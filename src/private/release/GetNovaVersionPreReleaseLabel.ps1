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
        return "$stem$( Get-NovaInitialPreReleaseNumber )"
    }

    return "$stem$( Get-NovaIncrementedPreReleaseNumber -PreReleaseNumber $preReleaseNumber )"
}

function Get-NovaInitialPreReleaseNumber {
    [CmdletBinding()]
    param()

    return '01'
}

function Get-NovaIncrementedPreReleaseNumber {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$PreReleaseNumber
    )

    $nextNumber = [int]$PreReleaseNumber + 1
    if ($PreReleaseNumber.Length -eq 1) {
        return $nextNumber
    }

    return $nextNumber.ToString("D$( $PreReleaseNumber.Length )")
}
