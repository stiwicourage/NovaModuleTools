function Test-ProjectSchema {
    [CmdletBinding()]
    param()

    Write-Verbose 'Running schema validation against Schema-Project.json'
    $schemaPath = Get-ResourceFilePath -FileName 'Schema-Project.json'
    try {
        $result = Test-Json -Path 'project.json' -Schema (Get-Content $schemaPath -Raw)
    } catch {
        Stop-NovaOperation -Message "Invalid project.json: $( $_.Exception.Message )" -ErrorId 'Nova.Configuration.ProjectSchemaValidationFailed' -Category InvalidData -TargetObject 'project.json'
    }

    return $result
}
