function ConvertTo-NovaCliArgumentArray {param([hashtable]$BoundParameters, [string[]]$Arguments) return ,@(@($Arguments) | Where-Object {$_})}
function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject) throw $Message}
