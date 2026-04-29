function Write-JsonFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][hashtable]$Data
    )

    $json = $Data | ConvertTo-Json -Depth 20
    Set-Content -LiteralPath $Path -Value $json -Encoding utf8
}
