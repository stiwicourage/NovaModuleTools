function Get-NovaCliNormalizedRootCommand {param([string]$Command) return $Command}
function Get-NovaCliCommandHelpDefinition {param([string]$Command) return @{}}
function Format-NovaCliCommandHelp {param($Definition, [string]$View) return $View}
function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw $Message}
