function Get-NovaEnvironmentVariableValue {param([string]$Name) return $null}
function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw $Message}
