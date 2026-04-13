function Get-NovaProjectInfo {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location).Path,
        [switch]$Version
    )
    $ProjectRoot = (Resolve-Path -LiteralPath $Path).Path
    $ProjectJson = [System.IO.Path]::Join($ProjectRoot, 'project.json')

    if (-not (Test-Path -LiteralPath $projectJson)) {
        throw "Not a project folder. project.json not found: $projectJson"
    }

    $jsonData = Read-ProjectJsonData -ProjectJsonPath $projectJson

    $Out = @{}
    $Out['ProjectJSON'] = $ProjectJson

    foreach ($key in $jsonData.Keys) {
        $Out[$key] = $jsonData[$key]
    }

    $booleanDefaults = [ordered]@{
        BuildRecursiveFolders = $true
        FailOnDuplicateFunctionNames = $true
        SetSourcePath = $true
        CopyResourcesToModuleRoot = $false
    }

    foreach ($boolKey in $booleanDefaults.Keys) {
        if (-not $Out.ContainsKey($boolKey)) {
            $Out[$boolKey] = $booleanDefaults[$boolKey]
            continue
        }

        $Out[$boolKey] = [bool]$Out[$boolKey]
    }

    $Out['Preamble'] = @(Get-ProjectPreamble -ProjectData $jsonData)

    $Out.ProjectJson = $projectJson
    $Out.PSTypeName = 'MTProjectInfo'
    $ProjectName = $jsonData.ProjectName

    ## Folders
    $Out['ProjectRoot'] = $ProjectRoot
    $Out['PublicDir'] = [System.IO.Path]::Join($ProjectRoot, 'src', 'public')
    $Out['PrivateDir'] = [System.IO.Path]::Join($ProjectRoot, 'src', 'private')
    $Out['ClassesDir'] = [System.IO.Path]::Join($ProjectRoot, 'src', 'classes')
    $Out['ResourcesDir'] = [System.IO.Path]::Join($ProjectRoot, 'src', 'resources')
    $Out['TestsDir'] = [System.IO.Path]::Join($ProjectRoot, 'tests')
    $Out['DocsDir'] = [System.IO.Path]::Join($ProjectRoot, 'docs')
    $Out['OutputDir'] = [System.IO.Path]::Join($ProjectRoot, 'dist')
    $Out['OutputModuleDir'] = [System.IO.Path]::Join($Out.OutputDir, $ProjectName)
    $Out['ModuleFilePSM1'] = [System.IO.Path]::Join($Out.OutputModuleDir, "$ProjectName.psm1")
    $Out['ManifestFilePSD1'] = [System.IO.Path]::Join($Out.OutputModuleDir, "$ProjectName.psd1")

    $projectInfo = [pscustomobject]$out
    if ($Version) {
        return $projectInfo.Version
    }

    return $projectInfo
}
