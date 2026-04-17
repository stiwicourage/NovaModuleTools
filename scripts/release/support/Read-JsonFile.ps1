function Read-JsonFile {
    param(
        [Parameter(Mandatory)][string]$Path
    )

    return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -AsHashtable)
}
