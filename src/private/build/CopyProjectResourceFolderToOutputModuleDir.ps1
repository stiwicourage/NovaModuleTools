function Copy-ProjectResourceFolderToOutputModuleDir {
    param(
        [Parameter(Mandatory)][string]$ResourceFolder,
        [Parameter(Mandatory)][string]$OutputModuleDir
    )

    Write-Verbose 'Files found in resource folder, Copying resource folder'
    Copy-Item -Path $ResourceFolder -Destination $OutputModuleDir -Recurse -Force -ErrorAction Stop
}
