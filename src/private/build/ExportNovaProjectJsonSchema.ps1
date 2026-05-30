function Export-NovaProjectJsonSchema {
    [CmdletBinding()]
    param()

    $projectInfo = Get-NovaProjectInfo
    $version = $projectInfo.Version
    $major = ($version -split '\.')[0]
    $schemaSource = Get-ResourceFilePath -FileName 'Schema-Project.json'
    $outputDir = Join-Path (Get-Location).Path "docs/schema/v$major"
    if (-not (Test-Path -LiteralPath $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir | Out-Null
    }
    $outputPath = Join-Path $outputDir 'project.json'
    Copy-Item -LiteralPath $schemaSource -Destination $outputPath -Force
    Write-Verbose "Schema exported to $outputPath"
}
