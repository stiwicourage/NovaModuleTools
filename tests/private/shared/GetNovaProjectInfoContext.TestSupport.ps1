function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject)
    throw $Message
}
function Read-ProjectJsonData {param([string]$ProjectJsonPath)}
