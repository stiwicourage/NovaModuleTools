function Get-NovaProjectInfoResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [switch]$Version
    )

    $projectRoot = $WorkflowContext.ProjectRoot
    $projectJson = $WorkflowContext.ProjectJson
    $jsonData = $WorkflowContext.JsonData
    if ($Version) {
        return $jsonData.Version
    }

    $projectData = [ordered]@{ProjectJSON = $projectJson}
    foreach ($key in $jsonData.Keys) {
        $projectData[$key] = $jsonData[$key]
    }

    $booleanDefaults = [ordered]@{BuildRecursiveFolders = $true; FailOnDuplicateFunctionNames = $true; SetSourcePath = $true; CopyResourcesToModuleRoot = $false}
    foreach ($defaultEntry in $booleanDefaults.GetEnumerator()) {
        $projectData[$defaultEntry.Key] = if ( $projectData.Contains($defaultEntry.Key)) {
            [bool]$projectData[$defaultEntry.Key]
        } else {
            $defaultEntry.Value
        }
    }

    $projectData['Preamble'] = @(Get-ProjectPreamble -ProjectData $jsonData)
    $projectData.PSTypeName = 'MTProjectInfo'
    $projectName = $jsonData.ProjectName
    $manifestSettings = Get-NovaResolvedProjectManifestSettings -ProjectData $projectData
    $projectData['Manifest'] = $manifestSettings
    $projectData['Package'] = Get-NovaResolvedProjectPackageSettings -ProjectData $projectData -ManifestSettings $manifestSettings -ProjectRoot $projectRoot
    $projectData['ProjectRoot'] = $projectRoot
    $projectData['PublicDir'] = [System.IO.Path]::Join($projectRoot, 'src', 'public')
    $projectData['PrivateDir'] = [System.IO.Path]::Join($projectRoot, 'src', 'private')
    $projectData['ClassesDir'] = [System.IO.Path]::Join($projectRoot, 'src', 'classes')
    $projectData['ResourcesDir'] = [System.IO.Path]::Join($projectRoot, 'src', 'resources')
    $projectData['TestsDir'] = [System.IO.Path]::Join($projectRoot, 'tests')
    $projectData['DocsDir'] = [System.IO.Path]::Join($projectRoot, 'docs')
    $projectData['OutputDir'] = [System.IO.Path]::Join($projectRoot, 'dist')
    $projectData['OutputModuleDir'] = [System.IO.Path]::Join($projectData.OutputDir, $projectName)
    $projectData['ModuleFilePSM1'] = [System.IO.Path]::Join($projectData.OutputModuleDir, "$projectName.psm1")
    $projectData['ManifestFilePSD1'] = [System.IO.Path]::Join($projectData.OutputModuleDir, "$projectName.psd1")

    return [pscustomobject]$projectData
}
