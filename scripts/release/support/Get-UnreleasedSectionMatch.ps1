function Get-UnreleasedSectionMatch {
    param(
        [Parameter(Mandatory)][string]$Text
    )

    $pattern = '(?ms)^##\s+\[Unreleased\]\s*\r?\n(?<body>.*?)(?=^##\s+\[|\z)'
    $match = [regex]::Match($Text, $pattern)

    if (-not $match.Success) {
        throw 'Could not find ## [Unreleased] section in CHANGELOG.md.'
    }

    return $match
}

