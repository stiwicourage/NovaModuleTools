function Get-NovaBuildProjectInfo {param([pscustomobject]$ProjectInfo)}
function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject)
    throw $Message
}
