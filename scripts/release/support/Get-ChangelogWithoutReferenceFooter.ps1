function Get-ChangelogWithoutReferenceFooter {
    param(
        [Parameter(Mandatory)][string]$Text
    )

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in ($Text -split '\r?\n')) {
        $lines.Add($line)
    }

    while ($lines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($lines[$lines.Count - 1])) {
        $lines.RemoveAt($lines.Count - 1)
    }

    while ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -match '^\[[^\]]+\]:\s+https://github\.com/.+$') {
        $lines.RemoveAt($lines.Count - 1)
    }

    while ($lines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($lines[$lines.Count - 1])) {
        $lines.RemoveAt($lines.Count - 1)
    }

    return ($lines -join "`n")
}


