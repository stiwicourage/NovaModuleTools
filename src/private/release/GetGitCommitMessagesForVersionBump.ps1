function Get-GitCommitMessageForVersionBump {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot '.git'))) {
        return @()
    }

    $format = '%s%n%b%n--END-COMMIT--'
    $lastTag = & git -C $ProjectRoot describe --tags --abbrev=0 2> $null

    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($lastTag)) {
        $raw = & git -C $ProjectRoot log "$lastTag..HEAD" --format=$format 2> $null
    }
    else {
        $raw = & git -C $ProjectRoot log --format=$format 2> $null
    }

    if ($LASTEXITCODE -ne 0 -or -not $raw) {
        return @()
    }

    $text = ($raw -join [Environment]::NewLine)
    $commits = $text -split '(?m)^--END-COMMIT--\r?$'
    return @($commits | ForEach-Object {$_.Trim()} | Where-Object {-not [string]::IsNullOrWhiteSpace($_)})
}
