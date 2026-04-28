function Write-ProjectJsonData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectJsonPath,
        [Parameter(Mandatory)][hashtable]$Data
    )

    $projectJsonContent = $Data | ConvertTo-Json -Depth 20
    Set-Content -LiteralPath $ProjectJsonPath -Value $projectJsonContent -Encoding utf8
}
