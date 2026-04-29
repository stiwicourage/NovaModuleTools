function Get-ClearedUnreleasedBody {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string]$Body
    )

    $headings = @(
    $Body -split '\r?\n' |
            Where-Object {$_ -match '^\s*###\s+'} |
            ForEach-Object {$_.TrimEnd()}
    )

    if (-not $headings) {
        return ''
    }

    return ($headings -join "`n`n")
}
