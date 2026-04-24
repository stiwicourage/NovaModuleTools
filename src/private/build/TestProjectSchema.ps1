function Test-ProjectSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Build', 'Pester')]
        [string]
        $Schema
    )
    Write-Verbose "Running Schema test against using $Schema schema"
    $SchemaPath = @{
        Build  = Get-ResourceFilePath -FileName 'Schema-Build.json'
        Pester = Get-ResourceFilePath -FileName 'Schema-Pester.json'
    }
    try {
        $result = switch ($Schema) {
            'Build' {
                Test-Json -Path 'project.json' -Schema (Get-Content $SchemaPath.Build -Raw)
            }
            'Pester' {
                Test-Json -Path 'project.json' -Schema (Get-Content $SchemaPath.Pester -Raw)
            }
        }
    }
    catch {
        Stop-NovaOperation -Message "Invalid project.json for the $Schema schema: $( $_.Exception.Message )" -ErrorId 'Nova.Configuration.ProjectSchemaValidationFailed' -Category InvalidData -TargetObject 'project.json'
    }

    return $result
}
