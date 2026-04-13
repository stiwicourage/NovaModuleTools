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
    $result = switch ($Schema) {
        'Build' {
            Test-Json -Path 'project.json' -Schema (Get-Content $SchemaPath.Build -Raw)
        }
        'Pester' {
            Test-Json -Path 'project.json' -Schema (Get-Content $SchemaPath.Pester -Raw)
        }
        Default { $false }
    }
    return $result
}
