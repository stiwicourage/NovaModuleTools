function Read-ProjectJsonData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectJsonPath
    )

    $projectJsonContent = Get-Content -LiteralPath $ProjectJsonPath -Raw
    if ( [string]::IsNullOrWhiteSpace($projectJsonContent)) {
        throw "project.json is empty: $ProjectJsonPath"
    }

    try {
        $jsonData = $projectJsonContent | ConvertFrom-Json -AsHashtable -ErrorAction Stop
    }
    catch {
        throw "project.json is not valid JSON: $ProjectJsonPath. $( $_.Exception.Message )"
    }

    if ($jsonData -isnot [hashtable]) {
        throw "project.json must contain a top-level JSON object: $ProjectJsonPath"
    }

    return $jsonData
}

