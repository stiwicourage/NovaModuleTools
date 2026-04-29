function Get-ChangelogReleaseVersionList {
    param(
        [Parameter(Mandatory)][string]$Text
    )

    return @(
    [regex]::Matches($Text, '(?m)^##\s+\[(?<version>[^\]]+)\]\s+-\s+') |
            ForEach-Object {$_.Groups['version'].Value}
    )
}
