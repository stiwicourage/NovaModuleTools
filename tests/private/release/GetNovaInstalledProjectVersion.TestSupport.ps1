function Get-NovaInstalledProjectManifestPath {param($ProjectInfo, $ModuleDirectoryPath) return '/nonexistent.psd1'}
function Format-NovaCliVersionString {param($Name, $Version) return "$Name $Version"}
function Get-NovaProjectInfo {return [pscustomobject]@{ProjectName='X'}}
function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
function Test-ModuleManifest {param($Path, $ErrorAction) return [pscustomobject]@{Version=[version]'1.2.3'}}
