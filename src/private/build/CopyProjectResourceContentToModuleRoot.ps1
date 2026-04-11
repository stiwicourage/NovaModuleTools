function Copy-ProjectResourceContentToModuleRoot {
    param(
        [Parameter(Mandatory)][System.IO.FileSystemInfo[]]$ItemList,
        [Parameter(Mandatory)][string]$OutputModuleDir
    )

    Write-Verbose 'Files found in resource folder, copying resource folder content'
    foreach ($item in $ItemList) {
        Copy-Item -Path $item.FullName -Destination $OutputModuleDir -Recurse -Force -ErrorAction Stop
    }
}
