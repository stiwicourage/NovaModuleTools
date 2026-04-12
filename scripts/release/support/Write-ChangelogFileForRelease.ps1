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

