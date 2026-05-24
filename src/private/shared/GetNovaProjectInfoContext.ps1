function Get-NovaProjectInfoContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    $projectRoot = Resolve-NovaProjectInfoRootPath -Path $Path
    $projectJson = [System.IO.Path]::Join($projectRoot, 'project.json')
    Assert-NovaProjectJsonPresence -ProjectRoot $projectRoot -ProjectJson $projectJson

    return [pscustomobject]@{
        ProjectRoot = $projectRoot
        ProjectJson = $projectJson
        JsonData = Read-ProjectJsonData -ProjectJsonPath $projectJson
    }
}

function Resolve-NovaProjectInfoRootPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path
    )

    try {
        $resolvedPath = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    } catch {
        Stop-NovaOperation -Message "Project path not found: $Path. Run Get-NovaProjectInfo from a Nova project root or pass -Path to an existing project folder." -ErrorId 'Nova.Environment.ProjectPathNotFound' -Category ObjectNotFound -TargetObject $Path
    }

    if (-not (Test-Path -LiteralPath $resolvedPath -PathType Container)) {
        Stop-NovaOperation -Message "Project path must be a folder: $resolvedPath. Pass -Path to the project root that contains project.json." -ErrorId 'Nova.Environment.ProjectPathNotDirectory' -Category InvalidArgument -TargetObject $resolvedPath
    }

    return $resolvedPath
}

function Assert-NovaProjectJsonPresence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ProjectRoot,
        [Parameter(Mandatory)][string]$ProjectJson
    )

    if (-not (Test-Path -LiteralPath $ProjectJson -PathType Leaf)) {
        Stop-NovaOperation -Message "project.json not found in project root: $ProjectRoot. Run Get-NovaProjectInfo from a folder that contains project.json or pass -Path to that folder." -ErrorId 'Nova.Environment.ProjectJsonNotFound' -Category ObjectNotFound -TargetObject $ProjectJson
    }
}
