function Get-NovaProjectInfo {return [pscustomobject]@{OutputModuleDir='/dist/X'; ProjectName='X'}}
function Publish-NovaBuiltModuleToRepository {param($ProjectInfo, $Repository, $ApiKey)}
function Publish-NovaBuiltModuleToDirectory {param($ProjectInfo, $ModuleDirectoryPath)}
function Resolve-NovaLocalPublishPath {param($ModuleDirectoryPath) return '/local/resolved'}
function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
