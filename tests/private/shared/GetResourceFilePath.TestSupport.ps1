function Get-NovaProjectInfo {param([string]$Path)}
function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject)
    throw $Message
}
