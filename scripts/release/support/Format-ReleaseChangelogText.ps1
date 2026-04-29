function Format-ReleaseChangelogText {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Date,
        [string[]]$AvailableReleaseVersions = (Get-AvailableReleaseVersionList),
        [string]$RepositoryUrl = (Get-ReleaseRepositoryUrl)
    )

    $match = Get-UnreleasedSectionMatch -Text $Text
    $unreleasedBody = $match.Groups['body'].Value.TrimEnd()
    $clearedUnreleasedBody = Get-ClearedUnreleasedBody -Body $unreleasedBody

    $before = $Text.Substring(0, $match.Index).TrimEnd()
    $afterStart = $match.Index + $match.Length
    $after = $Text.Substring($afterStart).TrimStart("`r", "`n")

    $unreleasedLines = @('## [Unreleased]')
    if (-not [string]::IsNullOrWhiteSpace($clearedUnreleasedBody)) {
        $unreleasedLines += ''
        $unreleasedLines += $clearedUnreleasedBody
    }

    $releaseLines = @("## [$Version] - $Date")
    if (-not [string]::IsNullOrWhiteSpace($unreleasedBody)) {
        $releaseLines += ''
        $releaseLines += $unreleasedBody
    }

    $sections = @($before, ($unreleasedLines -join "`n"), ($releaseLines -join "`n"))
    if (-not [string]::IsNullOrWhiteSpace($after)) {
        $sections += $after
    }

    $bodyText = (($sections | Where-Object {-not [string]::IsNullOrWhiteSpace($_)}) -join "`n`n").TrimEnd()
    $bodyWithoutFooter = Get-ChangelogWithoutReferenceFooter -Text $bodyText
    $referenceFooter = Get-ChangelogReferenceFooter -Text $bodyWithoutFooter -AvailableReleaseVersions $AvailableReleaseVersions -RepositoryUrl $RepositoryUrl

    if ( [string]::IsNullOrWhiteSpace($referenceFooter)) {
        return $bodyWithoutFooter.TrimEnd() + "`n"
    }

    return ($bodyWithoutFooter.TrimEnd() + "`n`n" + $referenceFooter.TrimEnd() + "`n")
}
