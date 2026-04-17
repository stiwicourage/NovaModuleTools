function Get-ChangelogReferenceFooter {
    param(
        [Parameter(Mandatory)][string]$Text,
        [string[]]$AvailableReleaseVersions = (Get-AvailableReleaseVersionList),
        [string]$RepositoryUrl = (Get-ReleaseRepositoryUrl)
    )

    $releaseVersions = Get-ChangelogReleaseVersionList -Text $Text
    if (-not $releaseVersions) {
        return ''
    }

    $allKnownVersions = @($releaseVersions + $AvailableReleaseVersions)
    $footerLines = [System.Collections.Generic.List[string]]::new()
    $footerLines.Add("[Unreleased]: $RepositoryUrl/compare/$( ConvertTo-ReleaseTagName -Version $releaseVersions[0] )...HEAD")

    foreach ($releaseVersion in $releaseVersions) {
        $previousVersion = Get-PreviousReleaseVersion -Version $releaseVersion -AvailableVersions $allKnownVersions
        $currentTag = ConvertTo-ReleaseTagName -Version $releaseVersion

        if ( [string]::IsNullOrWhiteSpace($previousVersion)) {
            $footerLines.Add("[$releaseVersion]: $RepositoryUrl/releases/tag/$currentTag")
            continue
        }

        $previousTag = ConvertTo-ReleaseTagName -Version $previousVersion
        $footerLines.Add("[$releaseVersion]: $RepositoryUrl/compare/$previousTag...$currentTag")
    }

    return $footerLines -join "`n"
}
