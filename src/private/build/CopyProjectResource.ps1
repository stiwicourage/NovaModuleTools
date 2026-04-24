function Copy-ProjectResource {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo
    )

    $data = Get-NovaBuildProjectInfo -ProjectInfo $ProjectInfo
    $resourceFolder = Get-ProjectResourceFolderPath -ProjectRoot $data.ProjectRoot
    if (-not (Test-Path $resourceFolder)) {
        return
    }

    $resourceItemList = @(Get-ProjectResourceItemList -ResourceFolder $resourceFolder)
    if ($resourceItemList.Count -eq 0) {
        return
    }

    if ($data.CopyResourcesToModuleRoot) {
        Copy-ProjectResourceContentToModuleRoot -ItemList $resourceItemList -OutputModuleDir $data.OutputModuleDir
        return
    }

    Copy-ProjectResourceFolderToOutputModuleDir -ResourceFolder $resourceFolder -OutputModuleDir $data.OutputModuleDir
}
