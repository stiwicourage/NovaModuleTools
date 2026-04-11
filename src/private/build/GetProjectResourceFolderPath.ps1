function Get-ProjectResourceFolderPath {
    param(
        [Parameter(Mandatory)][string]$ProjectRoot
    )

    return [System.IO.Path]::Join($ProjectRoot, 'src', 'resources')
}
