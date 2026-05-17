function Get-NovaBuildProjectInfo {param([pscustomobject]$ProjectInfo)}
function Get-ProjectResourceFolderPath {param([string]$ProjectRoot)}
function Get-ProjectResourceItemList {param([string]$ResourceFolder)}
function Copy-ProjectResourceContentToModuleRoot {param([System.IO.FileSystemInfo[]]$ItemList, [string]$OutputModuleDir)}
function Copy-ProjectResourceFolderToOutputModuleDir {param([string]$ResourceFolder, [string]$OutputModuleDir)}
