function Get-NovaProjectInfoContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    $projectRoot = (Resolve-Path -LiteralPath $Path).Path
    $projectJson = [System.IO.Path]::Join($projectRoot, 'project.json')
    if (-not (Test-Path -LiteralPath $projectJson)) {
        Stop-NovaOperation -Message "Not a project folder. project.json not found: $projectJson" -ErrorId 'Nova.Environment.ProjectJsonNotFound' -Category ObjectNotFound -TargetObject $projectJson
    }

    return [pscustomobject]@{
        ProjectRoot = $projectRoot
        ProjectJson = $projectJson
        JsonData = Read-ProjectJsonData -ProjectJsonPath $projectJson
    }
}

