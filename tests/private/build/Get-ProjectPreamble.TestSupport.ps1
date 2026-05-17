function Get-ProjectJsonValueTypeName {param($Value)}
function Format-ProjectJsonValue {param($Value)}
function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject)
    throw $Message
}
