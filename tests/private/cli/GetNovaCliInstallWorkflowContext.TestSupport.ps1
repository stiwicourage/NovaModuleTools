function Get-NovaCliInstallDirectory {param([string]$DestinationDirectory) return '/tmp/install'}
function Get-NovaCliLauncherPath {return '/src/nova'}
function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw $Message}
