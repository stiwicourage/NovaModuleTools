function Get-ResourceFilePath {param([string]$FileName)}
function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject)
    throw $Message
}
