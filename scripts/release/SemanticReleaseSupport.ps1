Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ReleaseDateString {
    return (Get-Date -Format 'yyyy-MM-dd')
}

function Read-JsonFile {
    param(
        [Parameter(Mandatory)][string]$Path
    )

    return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -AsHashtable)
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][hashtable]$Data
    )

    $json = $Data | ConvertTo-Json -Depth 20
    Set-Content -LiteralPath $Path -Value $json -Encoding utf8
}

function Write-ProjectJsonVersion {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Version
    )

    $project = Read-JsonFile -Path $Path
    $project.Version = $Version
    Write-JsonFile -Path $Path -Data $project
}

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

function Get-ClearedUnreleasedBody {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Body
    )

    $headings = @(
        $Body -split '\r?\n' |
            Where-Object { $_ -match '^\s*###\s+' } |
            ForEach-Object { $_.TrimEnd() }
    )

    if (-not $headings) {
        return ''
    }

    return ($headings -join "`n`n")
}

function Format-ReleaseChangelogText {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Date
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

    return (($sections | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "`n`n").TrimEnd() + "`n"
}

function Write-ChangelogFileForRelease {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Version,
        [Parameter(Mandatory)][string]$Date
    )

    $text = Get-Content -LiteralPath $Path -Raw
    $updated = Format-ReleaseChangelogText -Text $text -Version $Version -Date $Date
    Set-Content -LiteralPath $Path -Value $updated -Encoding utf8
}


