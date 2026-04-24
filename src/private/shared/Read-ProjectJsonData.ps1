function Read-ProjectJsonData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectJsonPath
    )

    $projectJsonContent = Get-Content -LiteralPath $ProjectJsonPath -Raw
    if ( [string]::IsNullOrWhiteSpace($projectJsonContent)) {
        Stop-NovaOperation -Message "project.json is empty: $ProjectJsonPath" -ErrorId 'Nova.Configuration.ProjectJsonEmpty' -Category InvalidData -TargetObject $ProjectJsonPath
    }

    try {
        $jsonData = $projectJsonContent | ConvertFrom-Json -AsHashtable
    }
    catch {
        Stop-NovaOperation -Message "project.json is not valid JSON: $ProjectJsonPath. $( $_.Exception.Message )" -ErrorId 'Nova.Configuration.ProjectJsonInvalidJson' -Category ParserError -TargetObject $ProjectJsonPath
    }

    if ($jsonData -isnot [hashtable]) {
        Stop-NovaOperation -Message "project.json must contain a top-level JSON object: $ProjectJsonPath" -ErrorId 'Nova.Configuration.ProjectJsonTopLevelObjectRequired' -Category InvalidData -TargetObject $ProjectJsonPath
    }

    return $jsonData
}
